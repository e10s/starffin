module icon;

auto getIconFromResource(string name)
{
    import org.eclipse.swt.internal.win32.OS : OS, StrToWCHARz;
    import org.eclipse.swt.internal.win32.WINTYPES : LR_DEFAULTSIZE;
    import org.eclipse.swt.SWT : SWT;
    import org.eclipse.swt.graphics.Image : Image;
    import org.eclipse.swt.widgets.Display : Display;

    auto hModule = OS.GetModuleHandle(null);
    auto hIcon = OS.LoadImage(hModule, StrToWCHARz(name), OS.IMAGE_ICON, 0, 0, LR_DEFAULTSIZE | OS.LR_SHARED);

    return Image.win32_new(Display.getCurrent(), SWT.ICON, hIcon);
}
