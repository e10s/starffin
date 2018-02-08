module starffin;

import org.eclipse.swt.SWT;

immutable name = "Starffin";

class ShellWrapper
{
    import org.eclipse.swt.widgets.Composite;
    import org.eclipse.swt.widgets.Display;
    import org.eclipse.swt.widgets.Shell;

    Shell shell;
    Composite mainView, statusBar;
    this()
    {
        import org.eclipse.swt.layout.GridData;
        import org.eclipse.swt.layout.GridLayout;

        shell = new Shell(new Display);
        shell.setText(name);

        auto gl = new GridLayout(1, false);
        gl.marginHeight = 0;
        gl.marginWidth = 0;
        gl.verticalSpacing = 0;
        shell.setLayout(gl);

        mainView = new Composite(shell, SWT.NULL);
        mainView.setLayoutData(new GridData(GridData.FILL_BOTH));
        gl = new GridLayout(3, false);
        mainView.setLayout(gl);

        statusBar = new Composite(shell, SWT.NULL | SWT.BORDER);
        statusBar.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
        gl = new GridLayout(3, false);
        statusBar.setLayout(gl);
    }

    alias shell this;
}

// 1st row
class Row1
{
    import org.eclipse.swt.widgets.Button;
    import org.eclipse.swt.widgets.Text;

    Text folderText;
    Button openFolderButton;
    this(C)(C parent)
    {
        import org.eclipse.swt.layout.GridData;
        import org.eclipse.swt.widgets.Label;
        import std.file : getcwd;

        new Label(parent, SWT.NULL).setText("Folder:");

        folderText = new Text(parent, SWT.SINGLE | SWT.BORDER);
        folderText.setText(getcwd());
        folderText.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));

        openFolderButton = new Button(parent, SWT.NULL);
        openFolderButton.setText("...");
    }
}

// 2nd row
class Row2
{
    import org.eclipse.swt.widgets.Text;

    Text searchText;
    this(C)(C parent)
    {
        import org.eclipse.swt.layout.GridData;
        import org.eclipse.swt.widgets.Label;

        new Label(parent, SWT.NULL).setText("Search:");

        searchText = new Text(parent, SWT.SINGLE | SWT.BORDER);
        auto gd = new GridData(GridData.FILL_HORIZONTAL);
        gd.horizontalSpan = 2;
        searchText.setLayoutData(gd);
    }
}

// 3rd row
class Row3
{
    import org.eclipse.swt.widgets.Button;

    Button searchButton;
    this(C)(C parent)
    {
        import org.eclipse.swt.layout.GridData;

        searchButton = new Button(parent, SWT.NULL);
        searchButton.setText("Search");
        auto gd = new GridData(GridData.HORIZONTAL_ALIGN_END);
        gd.horizontalSpan = 3;
        searchButton.setLayoutData(gd);
    }
}

// 4th row
class Row4
{
    //import org.eclipse.swt.widgets.Shell;
    import org.eclipse.swt.widgets.Table;

    Table resultTable;
    this(C)(C parent)
    {
        import org.eclipse.swt.layout.GridData;

        resultTable = new Table(parent, SWT.MULTI | SWT.FULL_SELECTION | SWT.BORDER | SWT.VIRTUAL);
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

// 5th row
class Row5
{
    import org.eclipse.swt.widgets.Label;

    Label statusLabel1, showingLabel;

    this(C)(C parent)
    {
        import org.eclipse.swt.layout.GridData;

        statusLabel1 = new Label(parent, SWT.NULL);
        statusLabel1.setText("STATUS LABEL 1");
        statusLabel1.setLayoutData(new GridData(SWT.FILL, SWT.CENTER, true, true));

        auto sep = new Label(parent, SWT.SEPARATOR);
        auto gd = new GridData(SWT.END, SWT.CENTER, false, true);
        gd.heightHint = statusLabel1.computeSize(SWT.DEFAULT, SWT.DEFAULT).y;
        sep.setLayoutData(gd);

        showingLabel = new Label(parent, SWT.NULL);
        showingLabel.setLayoutData(new GridData(SWT.END, SWT.CENTER, false, true));
    }
}

class GUI
{
    import org.eclipse.swt.widgets.Button;
    import org.eclipse.swt.widgets.Display;
    import org.eclipse.swt.widgets.Label;
    import org.eclipse.swt.widgets.Shell;
    import org.eclipse.swt.widgets.Text;
    import org.eclipse.swt.widgets.Table;
    import std.array : Appender;

    Shell shell;
    Display display;
    Text folderText, searchText;
    Button openFolderButton, searchButton;
    Table resultTable;
    Appender!(string[][]) resultTableData;
    Label statusLabel1, showingLabel;

    this()
    {
        auto shellWrapper = new ShellWrapper;
        shell = shellWrapper.shell;
        display = shell.getDisplay();
        auto r1 = new Row1(shellWrapper.mainView);
        folderText = r1.folderText;
        openFolderButton = r1.openFolderButton;
        searchText = new Row2(shellWrapper.mainView).searchText;
        searchButton = new Row3(shellWrapper.mainView).searchButton;
        resultTable = new Row4(shellWrapper.mainView).resultTable;
        auto r5 = new Row5(shellWrapper.statusBar);
        statusLabel1 = r5.statusLabel1;
        showingLabel = r5.showingLabel;

        setAdapters();
        updateShowingLabel(this);
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

        void setResultTableKeyAdapter()
        {
            import org.eclipse.swt.events.KeyAdapter;

            class ResultTableKeyAdapter : KeyAdapter
            {
                import org.eclipse.swt.events.KeyEvent;

                override void keyReleased(KeyEvent e)
                {
                    if (e.keyCode == SWT.DEL)
                    {
                        import std.algorithm.iteration : filter, map;
                        import std.algorithm.searching : canFind;
                        import std.array : empty, front;
                        import std.path : buildPath;
                        import std.range : enumerate, array;

                        auto indices = resultTable.getSelectionIndices();

                        if (indices.empty)
                        {
                            return;
                        }

                        auto paths = resultTable.getSelection()
                            .map!(a => buildPath(a.getText(1), a.getText(0))).array;

                        auto newData = resultTableData.data.enumerate.filter!(a => !indices.canFind(a.index))
                            .map!(a => a.value).array;
                        resultTableData.clear();
                        resultTableData.put(newData);
                        resultTable.removeAll();
                        resultTable.setItemCount(cast(int) resultTableData.data.length);

                        import std.algorithm.comparison : min;

                        immutable maxIdx = cast(int) resultTable.getItemCount() - 1;
                        resultTable.setSelection(min(maxIdx, indices.front));

                        updateShowingLabel(this.outer);

                        foreach (path; paths)
                        {
                            try
                            {
                                import trashcan : moveToTrash;

                                moveToTrash(path);
                            }
                            catch (Exception ex)
                            {
                                import std.stdio : stderr, writefln;

                                stderr.writefln("%s: %s", ex.msg, path);
                            }
                        }
                    }
                }
            }

            resultTable.addKeyListener(new ResultTableKeyAdapter);
        }

        void setResultTableSetDataListener()
        {
            import org.eclipse.swt.widgets.Listener;

            class ResultTableSetDataListener : Listener
            {
                import org.eclipse.swt.widgets.Event;

                void handleEvent(Event e)
                {
                    import org.eclipse.swt.widgets.TableItem;

                    auto item = cast(TableItem) e.item;
                    int index = resultTable.indexOf(item);
                    item.setText(resultTableData.data[index]);

                    updateShowingLabel(this.outer);
                }
            }

            resultTable.addListener(SWT.SetData, new ResultTableSetDataListener);
        }

        setFolderDropTargetAdapter();
        setFolderSelectionAdapter();
        setSearchSelectionAdapter();
        setTextKeyAdapter(folderText);
        setTextKeyAdapter(searchText);
        setResultTableKeyAdapter();
        setResultTableSetDataListener();
    }
}

void updateShowingLabel(GUI gui)
{
    import std.format : format;

    gui.showingLabel.setText(format!"Showing: %s"(gui.resultTable.getItemCount()));
    gui.showingLabel.getParent().layout();
}

import std.file : DirEntry;

void addTableItem(GUI gui, DirEntry entry)
{
    import std.format : format;
    import std.path : baseName, dirName;

    immutable s = entry.size;
    immutable t = entry.timeLastModified;
    gui.resultTableData.put([baseName(entry.name), dirName(entry.name),
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
    gui.resultTableData.clear();

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

    gui.resultTable.setItemCount(cast(int) gui.resultTableData.data.length);
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
