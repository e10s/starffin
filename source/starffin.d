module starffin;

import org.eclipse.swt.SWT : SWT;

debug
{
    version = Starffin_NoFileDeletion;
}

immutable name = "Starffin";
immutable buildId = {
    import std.array : join, split;
    import std.datetime.date : DateTime;

    return DateTime.fromSimpleString((t => [t[4], t[1], ("0" ~ t[2])[$ - 2 .. $]].join(
            "-") ~ " " ~ t[3])(__TIMESTAMP__.split)).toISOString.split("T").join;
}();
immutable windowTitle = {
    debug
    {
        return name ~ " [DEBUG] [Build " ~ buildId ~ "]";

    }
    else
    {
        return name;
    }
}();

class ShellWrapper
{
    import org.eclipse.swt.widgets.Composite : Composite;
    import org.eclipse.swt.widgets.Display : Display;
    import org.eclipse.swt.widgets.Shell : Shell;

    Shell shell;
    Composite mainView, statusBar;
    this()
    {
        import org.eclipse.swt.layout.GridData : GridData;
        import org.eclipse.swt.layout.GridLayout : GridLayout;

        shell = new Shell(new Display);
        shell.setText(windowTitle);

        auto gl = new GridLayout(1, false);
        gl.marginHeight = 0;
        gl.marginWidth = 0;
        gl.verticalSpacing = 0;
        shell.setLayout(gl);

        mainView = new Composite(shell, SWT.NULL);
        mainView.setLayoutData(new GridData(SWT.FILL, SWT.FILL, true, true));
        gl = new GridLayout(3, false);
        mainView.setLayout(gl);

        statusBar = new Composite(shell, SWT.NULL);
        statusBar.setLayoutData(new GridData(SWT.FILL, SWT.CENTER, true, false));
        gl = new GridLayout(5, false);
        statusBar.setLayout(gl);
    }

    alias shell this;
}

// 1st row
class Row1
{
    import org.eclipse.swt.widgets.Button : Button;
    import org.eclipse.swt.widgets.Combo : Combo;

    Combo folderText;
    Button openFolderButton;
    this(C)(C parent)
    {
        import org.eclipse.swt.layout.GridData : GridData;
        import org.eclipse.swt.widgets.Label : Label;

        new Label(parent, SWT.NULL).setText("Folder:");

        folderText = new Combo(parent, SWT.DROP_DOWN);
        auto gd = new GridData(SWT.FILL, SWT.CENTER, true, false);
        gd.widthHint = 200; //
        folderText.setLayoutData(gd);
        folderText.setVisibleItemCount(30);
        openFolderButton = new Button(parent, SWT.NULL);
        openFolderButton.setText("...");
    }
}

// 2nd row
class Row2
{
    import org.eclipse.swt.widgets.Combo : Combo;

    Combo searchText;
    this(C)(C parent)
    {
        import org.eclipse.swt.layout.GridData : GridData;
        import org.eclipse.swt.widgets.Label : Label;

        new Label(parent, SWT.NULL).setText("Search:");

        searchText = new Combo(parent, SWT.DROP_DOWN);
        auto gd = new GridData(SWT.FILL, SWT.CENTER, true, false);
        gd.horizontalSpan = 2;
        gd.widthHint = 200; //
        searchText.setLayoutData(gd);
        searchText.setVisibleItemCount(30);
    }
}

// 3rd row
class Row3
{
    import org.eclipse.swt.widgets.Button : Button;

    Button searchButton;
    this(C)(C parent)
    {
        import org.eclipse.swt.layout.GridData : GridData;

        searchButton = new Button(parent, SWT.NULL);
        searchButton.setText("Search");
        auto gd = new GridData(SWT.END, SWT.CENTER, false, false);
        gd.horizontalSpan = 3;
        searchButton.setLayoutData(gd);
    }
}

// 4th row
class Row4
{
    import org.eclipse.swt.widgets.Table : Table;

    Table resultTable;
    this(C)(C parent)
    {
        import org.eclipse.swt.layout.GridData : GridData;

        resultTable = new Table(parent, SWT.MULTI | SWT.FULL_SELECTION | SWT.BORDER | SWT.VIRTUAL);
        resultTable.setHeaderVisible(true);
        resultTable.setLinesVisible(true);
        auto gd = new GridData(SWT.FILL, SWT.FILL, true, true);
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
            import org.eclipse.swt.widgets.TableColumn : TableColumn;

            auto col = new TableColumn(resultTable, t.alignLeft ? SWT.LEFT : SWT.RIGHT);
            col.setText(t.text);
            col.setWidth(t.width);
        }
    }
}

// 5th row
class Row5
{
    import org.eclipse.swt.widgets.Label : Label;

    Label statusLabel, showingLabel, selectingLabel;

    this(C)(C parent)
    {
        import org.eclipse.swt.layout.GridData : GridData;

        statusLabel = new Label(parent, SWT.NULL);
        statusLabel.setLayoutData(new GridData(SWT.FILL, SWT.CENTER, true, true));

        auto gd = {
            auto a = new GridData(SWT.END, SWT.CENTER, false, true);
            a.heightHint = statusLabel.computeSize(SWT.DEFAULT, SWT.DEFAULT).y;
            return a;
        };

        auto sep1 = new Label(parent, SWT.SEPARATOR);
        sep1.setLayoutData(gd());

        showingLabel = new Label(parent, SWT.NULL);
        showingLabel.setLayoutData(new GridData(SWT.END, SWT.CENTER, false, true));

        auto sep2 = new Label(parent, SWT.SEPARATOR);
        sep2.setLayoutData(gd());

        selectingLabel = new Label(parent, SWT.NULL);
        selectingLabel.setLayoutData(new GridData(SWT.END, SWT.CENTER, false, true));
    }
}

class GUI
{
    import org.eclipse.swt.widgets.Button : Button;
    import org.eclipse.swt.widgets.Combo : Combo;
    import org.eclipse.swt.widgets.Display : Display;
    import org.eclipse.swt.widgets.Label : Label;
    import org.eclipse.swt.widgets.Shell : Shell;
    import org.eclipse.swt.widgets.Table : Table;
    import std.array : Appender;
    import history : HistoryManager;

    Shell shell;
    Display display;
    private Combo folderText, searchText;
    private Button openFolderButton, searchButton;
    private Table resultTable;
    private Appender!(string[][]) resultTableData;
    private Label statusLabel, showingLabel, selectingLabel;

    private HistoryManager folderHistory, searchHistory;

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
        statusLabel = r5.statusLabel;
        showingLabel = r5.showingLabel;
        selectingLabel = r5.selectingLabel;

        setAdapters();
        updateStatusLabel("Ready");
        updateShowingLabel();
        updateSelectingLabel();
        setWindowIcon();
    }

    this(HistoryManager folderHistory, HistoryManager searchHistory)
    {
        this();
        this.folderHistory = folderHistory;
        this.searchHistory = searchHistory;

        import std.array : array;

        folderText.setItems(folderHistory.sorted.array);
        if (!folderText.getItemCount())
        {
            import std.file : getcwd;

            folderText.setText(getcwd());
        }
        folderText.select(0);

        searchText.setItems(searchHistory.sorted.array);
        searchText.paste();
    }

    private void setAdapters()
    {
        {
            import org.eclipse.swt.dnd.DropTargetAdapter : DropTargetAdapter;
            import org.eclipse.swt.dnd.DND : DND;

            class FolderDropTargetAdapter : DropTargetAdapter
            {

                import org.eclipse.swt.dnd.DropTargetEvent : DropTargetEvent;

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

            import org.eclipse.swt.dnd.DropTarget : DropTarget;
            import org.eclipse.swt.dnd.FileTransfer : FileTransfer;
            import org.eclipse.swt.dnd.Transfer : Transfer;

            auto target = new DropTarget(folderText, DND.DROP_DEFAULT | DND.DROP_COPY);
            target.setTransfer([cast(Transfer) FileTransfer.getInstance()]);
            target.addDropListener(new FolderDropTargetAdapter);
        }

        {
            import org.eclipse.swt.events.SelectionAdapter : SelectionAdapter;

            class FolderSelectionAdapter : SelectionAdapter
            {
                import org.eclipse.swt.events.SelectionEvent : SelectionEvent;

                override void widgetSelected(SelectionEvent e)
                {
                    import org.eclipse.swt.widgets.DirectoryDialog : DirectoryDialog;

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

        {
            import org.eclipse.swt.events.SelectionAdapter : SelectionAdapter;

            class SearchSelectionAdapter : SelectionAdapter
            {
                import org.eclipse.swt.events.SelectionEvent : SelectionEvent;

                override void widgetSelected(SelectionEvent e)
                {
                    search();
                }
            }

            searchButton.addSelectionListener(new SearchSelectionAdapter);
        }

        foreach (text; [folderText, searchText])
        {
            import org.eclipse.swt.events.KeyAdapter : KeyAdapter;

            class TextKeyAdapter : KeyAdapter
            {
                import org.eclipse.swt.events.KeyEvent : KeyEvent;

                override void keyPressed(KeyEvent e)
                {
                    if ((e.keyCode == SWT.CR || e.keyCode == SWT.KEYPAD_CR)
                            && !text.getListVisible())
                    {

                        search();
                    }
                    else if (e.keyCode == SWT.DEL && text.getListVisible())
                    {
                        e.doit = false;

                        immutable idx = text.getSelectionIndex();
                        if (idx == -1)
                        {
                            return;
                        }

                        HistoryManager his;
                        if (text == folderText)
                        {
                            his = folderHistory;
                        }
                        else if (text == searchText)
                        {
                            his = searchHistory;
                        }
                        else
                        {
                            assert(0);
                        }

                        his.remove(text.getItem(idx));
                        text.remove(idx);
                        text.select(text.getItemCount() == idx ? idx - 1 : idx);
                    }
                }
            }

            text.addKeyListener(new TextKeyAdapter);
        }

        {
            import org.eclipse.swt.events.KeyAdapter : KeyAdapter;

            class ResultTableKeyAdapter : KeyAdapter
            {
                import org.eclipse.swt.events.KeyEvent : KeyEvent;

                override void keyPressed(KeyEvent e)
                {
                    if (e.stateMask == SWT.CTRL && e.keyCode == 'a')
                    {
                        resultTable.selectAll();
                        updateSelectingLabel();
                    }
                }

                override void keyReleased(KeyEvent e)
                {
                    if (e.keyCode == SWT.DEL)
                    {
                        import std.algorithm.iteration : filter, map, uniq;
                        import std.algorithm.searching : canFind, startsWith;
                        import std.algorithm.sorting : sort;
                        import std.array : array, empty, front;
                        import std.functional : binaryReverseArgs;
                        import std.path : buildPath, dirSeparator;
                        import std.range : enumerate;

                        auto indices = resultTable.getSelectionIndices();

                        if (indices.empty)
                        {
                            return;
                        }

                        auto pathsToBeRemoved = resultTable.getSelection()
                            .map!(a => buildPath(a.getText(1), a.getText(0))).array;

                        // Remove the items, in the folders to be removed, from the table.
                        auto locations = resultTable.getItems().map!(a => a.getText(1)).array;
                        indices ~= locations.enumerate
                            .filter!(loc => pathsToBeRemoved.canFind(loc.value)
                                    || pathsToBeRemoved.map!(a => a ~ dirSeparator)
                                    .canFind!(binaryReverseArgs!startsWith)(loc.value))
                            .map!(a => cast(int) a.index)
                            .array;

                        indices = indices.sort.uniq.array;

                        auto newData = resultTableData.data
                            .enumerate
                            .filter!(a => !indices.canFind(a.index))
                            .map!(a => a.value)
                            .array;
                        resetTableInfo();
                        resultTableData.put(newData);
                        reflectTableInfo();

                        import std.algorithm.comparison : min;

                        immutable maxIdx = cast(int) resultTable.getItemCount() - 1;
                        resultTable.setSelection(min(maxIdx, indices.front));
                        updateSelectingLabel();
                        updateShowingLabel();

                        foreach (path; pathsToBeRemoved)
                        {
                            version (Starffin_NoFileDeletion)
                            {
                                import std.experimental.logger : infof;

                                infof("[DRY RUN] moveToTrash(`%s`)", path);
                            }
                            else
                            {
                                try
                                {
                                    import trashcan : moveToTrash;

                                    moveToTrash(path);
                                }
                                catch (Exception ex)
                                {
                                    import std.experimental.logger : warningf;

                                    warningf("%s: %s", ex.msg, path);
                                }
                            }
                        }
                    }
                }
            }

            resultTable.addKeyListener(new ResultTableKeyAdapter);
        }

        {
            import org.eclipse.swt.widgets.Listener : Listener;

            class ResultTableSetDataListener : Listener
            {
                import org.eclipse.swt.widgets.Event : Event;

                void handleEvent(Event e)
                {
                    import org.eclipse.swt.widgets.TableItem : TableItem;

                    auto item = cast(TableItem) e.item;
                    item.setText(resultTableData.data[resultTable.indexOf(item)]);

                    updateShowingLabel();
                }
            }

            resultTable.addListener(SWT.SetData, new ResultTableSetDataListener);
        }

        {
            import org.eclipse.swt.events.SelectionAdapter : SelectionAdapter;

            class ResultTableSelectionAdapter : SelectionAdapter
            {
                import org.eclipse.swt.events.SelectionEvent : SelectionEvent;

                override void widgetSelected(SelectionEvent e)
                {
                    updateSelectingLabel();
                }

                override void widgetDefaultSelected(SelectionEvent e)
                {
                    import org.eclipse.swt.widgets.TableItem : TableItem;
                    import std.algorithm.iteration : filter;
                    import std.algorithm.searching : startsWith;
                    import std.array : array;
                    import std.file : exists, isDir, isFile;
                    import std.path : buildPath, dirSeparator;

                    auto item = cast(TableItem) e.item;
                    auto path = buildPath(item.getText(1), item.getText(0));

                    if (!path.exists)
                    {
                        return;
                    }

                    if (path.isDir)
                    {
                        auto newData = resultTableData.data.filter!(loc => loc[1] == path
                                || loc[1].startsWith(path ~ dirSeparator)).array;
                        resetTableInfo();
                        resultTableData.put(newData);
                        reflectTableInfo();
                        folderText.setText(path);
                    }
                    else if (path.isFile)
                    {
                        version (Windows)
                        {
                            import std.process : Config, spawnShell;

                            spawnShell(`explorer.exe /select,` ~ path, null,
                                    Config.suppressConsole);
                        }
                        else
                        {
                            import std.path : dirName;
                            import org.eclipse.swt.program.Program : Program;

                            Program.launch(dirName(path));
                        }
                    }
                }
            }

            resultTable.addSelectionListener(new ResultTableSelectionAdapter);
        }
    }

    private void reflectTableInfo()
    {
        resultTable.setItemCount(cast(int) resultTableData.data.length);
        updateSelectingLabel();
    }

    private void resetTableInfo()
    {
        resultTable.removeAll();
        resultTableData.clear();
        updateShowingLabel();
        updateSelectingLabel();
    }

    private void updateStatusLabel(string s)
    {
        statusLabel.setText(s);
    }

    private void updateShowingLabel()
    {
        import std.format : format;

        showingLabel.setText(format!"Showing: %s"(resultTable.getItemCount()));
        showingLabel.getParent().layout();
    }

    private void updateSelectingLabel()
    {
        import std.format : format;

        selectingLabel.setText(format!"Selecting: %s"(resultTable.getSelectionCount()));
        selectingLabel.getParent().layout();
    }

    import std.file : DirEntry;

    private void reserveTableItem(DirEntry entry)
    {
        import std.format : format;
        import std.path : baseName, dirName;

        immutable s = entry.size;
        immutable t = entry.timeLastModified;
        resultTableData.put([baseName(entry.name), dirName(entry.name),
                format!"%,d KB"(s / 1024 + (s % 1024 && 1)), format!"%d/%02d/%02d %d:%02d:%02d"(t.year,
                    t.month, t.day, t.hour, t.minute, t.second)]);
    }

    private void search()
    {
        auto isValid(string folderPath)
        {
            import std.file : exists, isDir;

            if (!folderPath.exists || !folderPath.isDir)
            {
                import org.eclipse.swt.widgets.MessageBox : MessageBox;
                import std.format : format;

                auto mb = new MessageBox(shell, SWT.ICON_ERROR);
                mb.setText(name);
                mb.setMessage(format!`"%s" is not a valid folder path.`(folderPath));
                mb.open();
                return false;
            }
            return true;
        }

        immutable folderPath = folderText.getText();

        if (!isValid(folderPath))
        {
            updateStatusLabel("Ready");
            return;
        }

        resetTableInfo();

        import std.uni : toLower;

        immutable partialName = searchText.getText().toLower;

        void dig(string folderPath, size_t depth)
        {
            import std.algorithm.iteration : filter;
            import std.file : DirEntry, FileException;

            DirEntry[] de;
            try
            {
                import std.array : array;
                import std.file : dirEntries, SpanMode;

                de = dirEntries(folderPath, SpanMode.shallow).array;
            }
            catch (FileException ex)
            {
                import std.experimental.logger : infof;

                infof("Skip: %s", folderPath);
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
                    reserveTableItem(entry);
                }
            }

            foreach (f; folders)
            {
                dig(f.name, depth + 1);
            }
        }

        updateStatusLabel("Searching");
        dig(folderPath, 0);

        reflectTableInfo();
        updateStatusLabel("Done");

        import std.array : array;

        folderHistory.update(folderText.getText());
        folderText.setItems(folderHistory.sorted.array);
        folderText.select(0);

        searchHistory.update(searchText.getText());
        searchText.setItems(searchHistory.sorted.array);
        searchText.select(0);
    }

    private void setWindowIcon()
    {
        import icon : getIconFromResource;

        auto windowIcon = getIconFromResource("STARFFIN_ICON");
        if (windowIcon !is null && !windowIcon.isDisposed())
        {
            shell.setImage(windowIcon);
        }
    }
}

void main()
{
    import history : HistoryManager;

    auto folderHistory = new HistoryManager("folder_history.dat");
    auto searchHistory = new HistoryManager("search_history.dat");
    scope (exit)
    {
        folderHistory.saveToFile();
        searchHistory.saveToFile();
    }
    auto gui = new GUI(folderHistory, searchHistory);
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
