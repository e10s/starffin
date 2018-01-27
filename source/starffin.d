import org.eclipse.swt.SWT;
import org.eclipse.swt.layout.all;
import org.eclipse.swt.widgets.all;

void main()
{
    immutable name = "Starffin";
    auto display = new Display;
    auto shell = new Shell(display);
    shell.setText(name);
    auto layout = new GridLayout;
    layout.numColumns = 3;
    shell.setLayout(layout);

    // 1st row
    auto folderLabel = new Label(shell, SWT.NULL);
    folderLabel.setText("Folder:");

    auto folderText = new Text(shell, SWT.SINGLE | SWT.BORDER);
    folderText.setText("Where to search");
    folderText.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));

    auto openFolderButton = new Button(shell, SWT.NULL);
    openFolderButton.setText("...");

    template FolderSelectionAdapter()
    {
        import org.eclipse.swt.events.SelectionAdapter;

        class FolderSelectionAdapter : SelectionAdapter
        {
            import org.eclipse.swt.events.SelectionEvent;

            override void widgetSelected(SelectionEvent e)
            {
                auto dialog = new DirectoryDialog(shell);
                auto path = dialog.open();
                folderText.setText(path);
            }
        }
    }

    openFolderButton.addSelectionListener(new FolderSelectionAdapter!());

    // 2nd row
    auto searchLabel = new Label(shell, SWT.NULL);
    searchLabel.setText("Search:");

    auto searchText = new Text(shell, SWT.SINGLE | SWT.BORDER);
    searchText.setText("partial_name");
    auto gd = new GridData(GridData.FILL_HORIZONTAL);
    gd.horizontalSpan = 2;
    searchText.setLayoutData(gd);

    // 3rd row
    auto searchButton = new Button(shell, SWT.NULL);
    searchButton.setText("Search");
    gd = new GridData(GridData.HORIZONTAL_ALIGN_END);
    gd.horizontalSpan = 3;
    searchButton.setLayoutData(gd);

    // 4th row
    auto resultTable = new Table(shell, SWT.MULTI | SWT.FULL_SELECTION | SWT.BORDER);
    resultTable.setHeaderVisible(true);
    resultTable.setLinesVisible(true);
    gd = new GridData(GridData.FILL_BOTH);
    gd.horizontalSpan = 3;
    resultTable.setLayoutData(gd);

    foreach (e; ["Name", "Location", "Size", "Last modified"])
    {
        auto col = new TableColumn(resultTable, SWT.LEFT);
        col.setText(e);
        col.setWidth(100);
    }

    // Fill dummy table data
    foreach (i; 0 .. 6)
    {
        auto item = new TableItem(resultTable, SWT.NULL);
        string[] data = ["Dummy Name", "Dummy Location", "Dummy Size", "Dummy Last mod"];
        item.setText(data);
    }

    shell.pack();
    shell.open();

    while (!shell.isDisposed())
    {
        if (!display.readAndDispatch())
        {
            display.sleep();
        }
    }
    display.dispose();
}
