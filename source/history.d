module history;

class HistoryManager
{
    private string filePath;
    private long[string] keyToPriority;
    private long maxPriority;

    this(string fileName)
    {
        import std.exception : ErrnoException;
        import std.file : thisExePath;
        import std.path : buildPath, dirName;
        import std.stdio : File;

        filePath = buildPath(dirName(thisExePath()), fileName);
        File f;

        try
        {
            f.open(filePath, "r");
        }
        catch (ErrnoException ex)
        {
            import std.stdio : stderr, writeln;

            stderr.writeln(ex.msg);
        }

        if (!f.isOpen)
        {
            return;
        }

        auto tmpPriority = -1L;
        maxPriority = tmpPriority;

        foreach (key; f.byLineCopy())
        {
            if (key in keyToPriority)
            {
                continue;
            }
            if (key is null)
            {
                key = "";
            }
            keyToPriority[key] = tmpPriority;
            if (tmpPriority == tmpPriority.min)
            {
                break;
            }
            tmpPriority--;
        }
    }

    void saveToFile()
    {
        import std.stdio : File;
        import std.exception : ErrnoException;

        File f;

        try
        {
            f.open(filePath, "w");
        }
        catch (ErrnoException ex)
        {
            import std.stdio : stderr, writeln;

            stderr.writeln(ex.msg);
        }

        if (!f.isOpen)
        {
            return;
        }

        foreach (key; sorted)
        {
            f.writeln(key);
        }
    }

    @property auto sorted()
    {
        import std.algorithm.iteration : map;
        import std.algorithm.sorting : sort;
        import std.range : array, byPair;

        return keyToPriority.byPair.array.sort!"a.value>b.value".map!"a.key";
    }

    void update(string path)
    {
        maxPriority++;
        keyToPriority[path] = maxPriority;
    }

    void remove(string path)
    {
        keyToPriority.remove(path);
    }
}
