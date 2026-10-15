import com.creativemd.littletiles.client.render.cache.IRenderDataCache;
import org.objectweb.asm.ClassReader;
import org.objectweb.asm.ClassWriter;
import org.objectweb.asm.tree.ClassNode;
import org.taumc.celeritas.impl.compat.littletiles.LittleTilesBufferCopy;
import org.taumc.celeritas.impl.compat.littletiles.LittleTilesMixinPlugin;
import org.taumc.celeritas.impl.render.terrain.compile.QuadVertexAlpha;

import java.lang.reflect.*;
import java.nio.*;
import java.nio.file.*;
import java.util.concurrent.*;

/** Runs against original LT cache bytecode transformed by the real bridge plugin. */
public final class BridgeQcCheck {
    private static final String CACHE = "com.creativemd.littletiles.client.render.cache.LayeredRenderBufferCache";
    private static int checks;

    private static void check(boolean value, String message) {
        if (!value) throw new AssertionError(message);
        checks++;
    }

    public static void main(String[] args) throws Exception {
        int[] colors = {0xFF000000, 0xFF123456, 0xFFFFFFFF, 0xFF987654};
        check(QuadVertexAlpha.isOpaque(colors[0], colors[1], colors[2], colors[3]), "opaque RGB must remain optimizable");
        for (int vertex = 0; vertex < 4; vertex++) {
            int original = colors[vertex];
            for (int alpha = 0; alpha < 255; alpha++) {
                colors[vertex] = (original & 0xFFFFFF) | (alpha << 24);
                check(!QuadVertexAlpha.isOpaque(colors[0], colors[1], colors[2], colors[3]), "partial alpha at vertex " + vertex);
            }
            colors[vertex] = original;
        }

        ByteBuffer shared = ByteBuffer.allocateDirect(112).order(ByteOrder.nativeOrder());
        for (int i = 0; i < 28; i++) shared.putInt(i * 4, i);
        shared.position(17);
        shared.limit(109);
        ByteBuffer view = LittleTilesBufferCopy.independentView(shared);
        check(view != shared && view.order() == shared.order(), "independent cursor and byte order");
        view.position(0);
        view.limit(112);
        view.position(112);
        check(shared.position() == 17 && shared.limit() == 109, "combine cursor must not mutate a shared cache");
        check(LittleTilesBufferCopy.independentView(null) == null, "null cache buffer remains null");

        ClassNode node = new ClassNode();
        new ClassReader(Files.readAllBytes(Paths.get(args[0]))).accept(node, 0);
        LittleTilesMixinPlugin plugin = new LittleTilesMixinPlugin();
        plugin.preApply(CACHE, node, "LayeredRenderBufferCacheMixin", null);
        ClassWriter writer = new ClassWriter(0);
        node.accept(writer);
        final byte[] transformed = writer.toByteArray();
        ClassLoader loader = new ClassLoader(BridgeQcCheck.class.getClassLoader()) {
            @Override protected Class<?> loadClass(String name, boolean resolve) throws ClassNotFoundException {
                if (!CACHE.equals(name)) return super.loadClass(name, resolve);
                Class<?> result = findLoadedClass(name);
                if (result == null) result = defineClass(name, transformed, 0, transformed.length);
                if (resolve) resolveClass(result);
                return result;
            }
        };
        Class<?> type = loader.loadClass(CACHE);
        for (String name : new String[]{"get", "hasAdditional", "beforeUpdate", "afterUpdate", "setEmpty", "additional", "set", "setUploaded", "setEmptyIfEqual"}) {
            boolean found = false;
            for (Method method : type.getDeclaredMethods()) if (method.getName().equals(name)) {
                check(Modifier.isSynchronized(method.getModifiers()), name + " must use the cache monitor");
                found = true;
            }
            check(found, "expected cache method " + name);
        }
        Object cache = type.newInstance();
        Field queue = type.getDeclaredField("queue"), additional = type.getDeclaredField("additional");
        queue.setAccessible(true);
        additional.setAccessible(true);
        CountDownLatch reading = new CountDownLatch(1), releaseRead = new CountDownLatch(1);
        IRenderDataCache blockingData = new IRenderDataCache() {
            @Override public ByteBuffer byteBuffer() {
                reading.countDown();
                try { if (!releaseRead.await(3, TimeUnit.SECONDS)) throw new AssertionError("reader timeout"); }
                catch (InterruptedException e) { throw new AssertionError(e); }
                return ByteBuffer.allocateDirect(112);
            }
            @Override public int length() { return 112; }
            @Override public int vertexCount() { return 4; }
        };
        ((IRenderDataCache[])queue.get(cache))[0] = blockingData;
        additional.set(cache, new IRenderDataCache[4]);
        ExecutorService workers = Executors.newFixedThreadPool(2);
        try {
            Future<?> reader = workers.submit(() -> invoke(type, cache, "get", new Class<?>[]{int.class}, 0));
            check(reading.await(2, TimeUnit.SECONDS), "reader entered real LT combine()");
            CountDownLatch writerStarted = new CountDownLatch(1), writerFinished = new CountDownLatch(1);
            Future<?> transition = workers.submit(() -> {
                writerStarted.countDown();
                invoke(type, cache, "afterUpdate", new Class<?>[0]);
                writerFinished.countDown();
            });
            check(writerStarted.await(2, TimeUnit.SECONDS), "transition started");
            check(!writerFinished.await(200, TimeUnit.MILLISECONDS), "transition may not clear additional while get is reading it");
            releaseRead.countDown();
            reader.get(2, TimeUnit.SECONDS);
            transition.get(2, TimeUnit.SECONDS);
            check(additional.get(cache) == null, "transition completes after read releases cache monitor");
        } finally {
            releaseRead.countDown();
            workers.shutdownNow();
        }
        try {
            plugin.preApply(CACHE, new ClassNode(), "LayeredRenderBufferCacheMixin", null);
            throw new AssertionError("unsupported cache API must fail explicitly");
        } catch (IllegalStateException expected) { checks++; }
        System.out.println("PASS: " + checks + " alpha, cursor, cache API and deterministic transition-lock checks");
    }

    private static Object invoke(Class<?> type, Object cache, String name, Class<?>[] parameters, Object... args) {
        try { return type.getMethod(name, parameters).invoke(cache, args); }
        catch (ReflectiveOperationException e) { throw new AssertionError(e); }
    }
}
