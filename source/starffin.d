import org.eclipse.swt.SWT;
import org.eclipse.swt.layout.all;
import org.eclipse.swt.widgets.all;

import std.file;

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
    folderText.setText(getcwd());
    folderText.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));

    auto openFolderButton = new Button(shell, SWT.NULL);
    openFolderButton.setText("...");

    // 2nd row
    auto searchLabel = new Label(shell, SWT.NULL);
    searchLabel.setText("Search:");

    auto searchText = new Text(shell, SWT.SINGLE | SWT.BORDER);
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
    gd.heightHint = 400;
    resultTable.setLayoutData(gd);

    import std.typecons : tuple;

    foreach (t; [tuple("Name", 120, true), tuple("Location", 180, true),
            tuple("Size", 100, false), tuple("Last modified", 140, true)])
    {
        auto col = new TableColumn(resultTable, t[2] ? SWT.LEFT : SWT.RIGHT);
        col.setText(t[0]);
        col.setWidth(t[1]);
    }

    void setFolderDropTargetAdapter()
    {
        import org.eclipse.swt.dnd.all;

        class FolderDropTargetAdapter : DropTargetAdapter
        {
            override void dragEnter(DropTargetEvent e)
            {
                e.detail = DND.DROP_COPY;
            }

            override void drop(DropTargetEvent e)
            {
                import java.lang.wrappers;
                import std.array;

                auto dropped = e.data.stringArrayFromObject;
                if (!dropped.empty)
                {
                    folderText.setText(dropped.front);
                }
            }
        }

        auto target = new DropTarget(folderText, DND.DROP_DEFAULT | DND.DROP_COPY);
        target.setTransfer([cast(Transfer) FileTransfer.getInstance()]);
        target.addDropListener(new FolderDropTargetAdapter);
    }

    void setFolderSelectionAdapter()
    {
        import org.eclipse.swt.events.SelectionAdapter;

        class FolderSelectionAdapter : SelectionAdapter
        {
            import org.eclipse.swt.events.SelectionEvent;

            override void widgetSelected(SelectionEvent e)
            {
                auto dialog = new DirectoryDialog(shell);
                dialog.setFilterPath(folderText.getText());
                auto path = dialog.open();
                if (path)
                {
                    folderText.setText(path);
                }
            }
        }

        openFolderButton.addSelectionListener(new FolderSelectionAdapter);
    }

    void searchImpl()
    {
        import std.file;

        auto dirPath = folderText.getText();
        if (!exists(dirPath) || !isDir(dirPath))
        {
            auto mb = new MessageBox(shell, SWT.ICON_ERROR);
            mb.setText(name);
            import std.format;

            mb.setMessage(format(`"%s" is not a valid folder path.`, dirPath));
            mb.open();
            return;
        }

        resultTable.removeAll();

        import std.uni;
        import std.range;
        import std.algorithm.iteration : filter;

        auto partialName = searchText.getText().toLower;
        auto de = dirEntries(dirPath, SpanMode.shallow).array;
        auto de2 = de.filter!(a => a.isDir).chain(de.filter!(a => a.isFile));
        foreach (DirEntry entry; de2)
        {
            import std.algorithm.searching;
            import std.path;

            auto itemName = baseName(entry.name);
            if (itemName.toLower.canFind(partialName))
            {
                import std.datetime.systime;
                import std.format;

                immutable t = entry.timeLastModified;
                auto item = new TableItem(resultTable, SWT.NULL);
                item.setText([itemName, dirName(entry.name), format!"%,d"(entry.size),
                        format!"%d/%02d/%02d %d:%02d:%02d"(t.year, t.month,
                            t.day, t.hour, t.minute, t.second)]);
            }
        }
    }

    void setSearchSelectionAdapter()
    {
        import org.eclipse.swt.events.SelectionAdapter;

        class SearchSelectionAdapter : SelectionAdapter
        {
            import org.eclipse.swt.events.SelectionEvent;

            override void widgetSelected(SelectionEvent e)
            {
                searchImpl();
            }
        }

        searchButton.addSelectionListener(new SearchSelectionAdapter);
    }

    void setTextKeyAdapter(Text text)
    {
        import org.eclipse.swt.events.KeyAdapter;

        class TextKeyAdapter : KeyAdapter
        {
            import org.eclipse.swt.events.KeyEvent;

            override void keyReleased(KeyEvent e)
            {
                if (e.keyCode == SWT.CR || e.keyCode == SWT.KEYPAD_CR)
                {
                    searchImpl();
                }
            }
        }

        text.addKeyListener(new TextKeyAdapter);

    }

    setFolderDropTargetAdapter();
    setFolderSelectionAdapter();
    setSearchSelectionAdapter();
    setTextKeyAdapter(folderText);
    setTextKeyAdapter(searchText);

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
