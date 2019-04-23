# foreach-cli
CLI utility to execute a command for each file matching a glob. Originally a fork of [each-cli][https://www.npmjs.com/package/each-cli], but then completely rewritten in order to provoke simplicity and eliminate annoying bugs. It differs form the original mainly by setting the CWD (current working directory) to the directory the foreach command was executed from, as opposed to the original package's behavior which set the CWD to the matched file's directory. It also takes the command arguments as strings to allow more complex commands such as piping.


Installation:
------
```bash
npm install foreach-cli
```


Usage:
------
**Command Line**
```
foreach -g <glob> -x <command to execute>
```

**Command Line Options:**

```bash
-g, --glob        Specify the glob
-i, --ignore      Glob ignore pattern(s)
-x, --execute     Command to execute upon file addition/change
-c, --forceColor  Force color TTY output (pass --no-c to disable)
-t, --trim        Trims the output of the command executions to only show the first X characters of the output
-C, --concurrent  Execute commands concurrently (pass --no-C to disable)
-h                Show help
--version         Show version number                                    
```

**Executing Command Placeholders**
```
"path"  -  full path and filename
"root"  -  file root
"dir"   -  path without the filename
"reldir"-  directory name of file relative to the glob provided
"base"  -  file name and extension
"ext"   -  just file extension
"name"  -  just file name
```






Example:
------
#### Command Line:
```
foreach -g "**/*.tar" -x "tar xvf #{path}"
foreach -g "*/*.jpg" -x "convert #{path}.jpg #{dir}/#{name}.converted.png"
```

