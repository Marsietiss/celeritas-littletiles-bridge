import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.Arrays;
import org.taumc.celeritas.impl.compat.littletiles.LittleTilesBufferCopy;

public final class LittleTilesBufferCopyCheck {
    private static int checks;
    private static void check(boolean value, String message) {
        if (!value) throw new AssertionError(message);
        checks++;
    }
    private static void rejected(ByteBuffer data, int length, int stride) {
        try {
            LittleTilesBufferCopy.snapshot(data, length, stride);
            throw new AssertionError("Invalid input accepted");
        } catch (IllegalArgumentException expected) {
            checks++;
        }
    }
    public static void main(String[] args) {
        for (boolean direct : new boolean[]{false, true}) {
            ByteBuffer source = (direct ? ByteBuffer.allocateDirect(224) : ByteBuffer.allocate(224))
                    .order(ByteOrder.nativeOrder());
            int[] expected = new int[56];
            for (int i = 0; i < expected.length; i++) {
                expected[i] = (i % 7 < 3) ? Float.floatToRawIntBits(i * 0.125f) : (0x80ABCD00 | i);
                source.putInt(expected[i]);
            }
            source.position(20);
            source.limit(224);
            check(Arrays.equals(expected, LittleTilesBufferCopy.snapshot(source, 224, 28)), "Quad data changed");
            check(source.position() == 20 && source.limit() == 224, "Shared buffer cursor changed");
            check(LittleTilesBufferCopy.snapshot(source.asReadOnlyBuffer(), 112, 28).length == 28, "Read-only or bounded copy failed");
            check(LittleTilesBufferCopy.snapshot(source, 0, 28).length == 0, "Empty buffer failed");
            rejected(source, 111, 28);
            rejected(source, 336, 28);
            rejected(source, -112, 28);
            rejected(source, 112, 0);
        }
        System.out.println("PASS: " + checks + " LittleTiles buffer-copy checks");
    }
}
