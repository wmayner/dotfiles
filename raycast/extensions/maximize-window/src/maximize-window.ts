// src/maximize-window.ts
import { WindowManagement, showHUD, Toast, showToast } from "@raycast/api";

export default async function Command() {
    try {
        const win = await WindowManagement.getActiveWindow(); // <-- correct API
        if (!win) {
            await showHUD("No active window");
            return;
        }

        const desktops = await WindowManagement.getDesktops();
        const desk = desktops.find((d) => d.id === win.desktopId);
        if (!desk) {
            await showHUD("No desktop for window");
            return;
        }

        await WindowManagement.setWindowBounds({
            id: win.id,
            bounds: {
                position: { x: 0, y: 0 },
                size: { width: desk.size.width, height: desk.size.height },
            },
        });
    } catch (err: any) {
        await showToast({ style: Toast.Style.Failure, title: "Maximize failed", message: String(err?.message ?? err) });
    }
}
