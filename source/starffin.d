module starffin;

import org.eclipse.swt.SWT;

immutable name = "Starffin";

class ShellWrapper
{
    import org.eclipse.swt.widgets.Display;
    import org.eclipse.swt.widgets.Shell;

    Shell shell;
    this()
    {
        import org.eclipse.swt.layout.GridLayout;

        shell = new Shell(new Display);
        shell.setText(name);
        shell.setLayout(new GridLayout(3, false));
    }

    alias shell this;
}

// 1st row
class Row1
{
    import org.eclipse.swt.widgets.Button;
    import org.eclipse.swt.widgets.Shell;
    import org.eclipse.swt.widgets.Text;

    Text folderText;
    Button openFolderButton;
    this(Shell shell)
    {
        import org.eclipse.swt.layout.GridData;
        import org.eclipse.swt.widgets.Label;
        import std.file : getcwd;

        new Label(shell, SWT.NULL).setText("Folder:");

        folderText = new Text(shell, SWT.SINGLE | SWT.BORDER);
        folderText.setText(getcwd());
        folderText.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));

        openFolderButton = new Button(shell, SWT.NULL);
        openFolderButton.setText("...");
    }
}

// 2nd row
class Row2
{
    import org.eclipse.swt.widgets.Shell;
    import org.eclipse.swt.widgets.Text;

    Text searchText;
    this(Shell shell)
    {
        import org.eclipse.swt.layout.GridData;
        import org.eclipse.swt.widgets.Label;

        new Label(shell, SWT.NULL).setText("Search:");

        searchText = new Text(shell, SWT.SINGLE | SWT.BORDER);
        auto gd = new GridData(GridData.FILL_HORIZONTAL);
        gd.horizontalSpan = 2;
        searchText.setLayoutData(gd);
    }
}

// 3rd row
class Row3
{
    import org.eclipse.swt.widgets.Button;
    import org.eclipse.swt.widgets.Shell;

    Button searchButton;
    this(Shell shell)
    {
        import org.eclipse.swt.layout.GridData;

        searchButton = new Button(shell, SWT.NULL);
        searchButton.setText("Search");
        auto gd = new GridData(GridData.HORIZONTAL_ALIGN_END);
        gd.horizontalSpan = 3;
        searchButton.setLayoutData(gd);
    }
}

// 4th row
class Row4
{
    import org.eclipse.swt.widgets.Shell;
    import org.eclipse.swt.widgets.Table;

    Table resultTable;
    this(Shell shell)
    {
        import org.eclipse.swt.layout.GridData;

        resultTable = new Table(shell, SWT.MULTI | SWT.FULL_SELECTION | SWT.BORDER);
        resultTable.setHeaderVisible(true);
        resultTable.setLinesVisible(true);
        auto gd = new GridData(GridData.FILL_BOTH);
        gd.horizontalSpan = 3;
        gd.heightHint = 400;
        resultTable.setLayoutData(gd);

        buildTableColumns();
    }

    private void buildTableColumns()
    {
        import std.typecons : Tuple;

        alias ColumnSpec = Tuple!(string, "text", int, "width", bool, "alignLeft");
        auto tableColumns = [
            ColumnSpec("Name", 120, true), ColumnSpec("Location", 180, true),
            ColumnSpec("Size", 100, false), ColumnSpec("Last modified", 140, true)
        ];

        foreach (t; tableColumns)
        {
            import org.eclipse.swt.widgets.TableColumn;

            auto col = new TableColumn(resultTable, t.alignLeft ? SWT.LEFT : SWT.RIGHT);
            col.setText(t.text);
            col.setWidth(t.width);
        }
    }
}

class GUI
{
    import org.eclipse.swt.widgets.Button;
    import org.eclipse.swt.widgets.Display;
    import org.eclipse.swt.widgets.Shell;
    import org.eclipse.swt.widgets.Text;
    import org.eclipse.swt.widgets.Table;

    Shell shell;
    Display display;
    Text folderText, searchText;
    Button openFolderButton, searchButton;
    Table resultTable;
    this()
    {
        shell = new ShellWrapper;
        display = shell.getDisplay();
        auto r1 = new Row1(shell);
        folderText = r1.folderText;
        openFolderButton = r1.openFolderButton;
        searchText = new Row2(shell).searchText;
        searchButton = new Row3(shell).searchButton;
        resultTable = new Row4(shell).resultTable;

        setAdapters();
    }

    private void setAdapters()
    {
        void setFolderDropTargetAdapter()
        {
            import org.eclipse.swt.dnd.DropTargetAdapter;
            import org.eclipse.swt.dnd.DND;

            class FolderDropTargetAdapter : DropTargetAdapter
            {

                import org.eclipse.swt.dnd.DropTargetEvent;

                override void dragEnter(DropTargetEvent e)
                {

                    e.detail = DND.DROP_COPY;
                }

                override void drop(DropTargetEvent e)
                {
                    import java.lang.wrappers : stringArrayFromObject;
                    import std.array : empty, front;

                    auto dropped = e.data.stringArrayFromObject;
                    if (!dropped.empty)
                    {
                        folderText.setText(dropped.front);
                    }
                }
            }

            import org.eclipse.swt.dnd.DropTarget;
            import org.eclipse.swt.dnd.FileTransfer;
            import org.eclipse.swt.dnd.Transfer;

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
                    import org.eclipse.swt.widgets.DirectoryDialog;

                    auto dialog = new DirectoryDialog(openFolderButton.getShell());
                    dialog.setFilterPath(folderText.getText());
                    if (auto path = dialog.open())
                    {
                        folderText.setText(path);
                    }
                }
            }

            openFolderButton.addSelectionListener(new FolderSelectionAdapter);
        }

        void setSearchSelectionAdapter()
        {
            import org.eclipse.swt.events.SelectionAdapter;

            class SearchSelectionAdapter : SelectionAdapter
            {
                import org.eclipse.swt.events.SelectionEvent;

                override void widgetSelected(SelectionEvent e)
                {
                    searchImpl(this.outer);
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
                        searchImpl(this.outer);
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
    }
}

import std.file : DirEntry;

void addTableItem(GUI gui, DirEntry entry)
{
    import org.eclipse.swt.widgets.TableItem;
    import std.format : format;
    import std.path : baseName, dirName;

    immutable s = entry.size;
    immutable t = entry.timeLastModified;
    auto item = new TableItem(gui.resultTable, SWT.NULL);
    item.setText([baseName(entry.name), dirName(entry.name),
            format!"%,d KB"(s / 1024 + (s % 1024 && 1)), format!"%d/%02d/%02d %d:%02d:%02d"(t.year,
                t.month, t.day, t.hour, t.minute, t.second)]);
}

void searchImpl(GUI gui)
{
    auto isValid(string folderPath)
    {
        import std.file : exists, isDir;

        if (!folderPath.exists || !folderPath.isDir)
        {
            import org.eclipse.swt.widgets.MessageBox;
            import std.format : format;

            auto mb = new MessageBox(gui.shell, SWT.ICON_ERROR);
            mb.setText(name);
            mb.setMessage(format!`"%s" is not a valid folder path.`(folderPath));
            mb.open();
            return false;
        }
        return true;
    }

    immutable folderPath = gui.folderText.getText();

    if (!isValid(folderPath))
    {
        return;
    }

    gui.resultTable.removeAll();

    import std.uni : toLower;

    immutable partialName = gui.searchText.getText().toLower;

    void dig(string folderPath, size_t depth)
    {
        import std.algorithm.iteration : filter;
        import std.file : DirEntry, FileException;

        DirEntry[] de;
        try
        {
            import std.file : dirEntries, SpanMode;
            import std.range : array;

            de = dirEntries(folderPath, SpanMode.shallow).array;
        }
        catch (FileException ex)
        {
            import std.stdio : stderr, writeln;

            stderr.writeln("Skip: ", folderPath);
        }

        import std.range : chain, empty;

        if (de.empty)
        {
            return;
        }

        auto folders = de.filter!(a => a.isDir);
        auto files = de.filter!(a => a.isFile);
        foreach (DirEntry entry; chain(folders, files))
        {
            import std.algorithm.searching : canFind;
            import std.path : baseName;

            if (baseName(entry.name).toLower.canFind(partialName))
            {
                addTableItem(gui, entry);
            }
        }

        foreach (f; folders)
        {
            dig(f.name, depth + 1);
        }
    }

    dig(folderPath, 0);
}

void main()
{
    auto gui = new GUI;
    gui.shell.pack();
    gui.shell.open();

    while (!gui.shell.isDisposed())
    {
        if (!gui.display.readAndDispatch())
        {
            gui.display.sleep();
        }
    }
    gui.display.dispose();
}
