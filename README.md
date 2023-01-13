# yon

`yon` is a tool for interactive shells that simplifies prompting the user binary "yes or no"-questions.
It works with all POSIX compatible shells, such as `sh`, `bash`, `zsh` and many more, and has no further dependencies.

## Getting Started

Dowload the [yon.sh](./yon.sh) file or clone this repository to a directory of your choice.
In any new terminal, where you want to use `yon`, source [yon.sh](./yon.sh) via
```sh
>$ source /path/to/yon.sh
```
Now you can call it by its name: `yon`.
Try
```sh
>$ yon --help
```
to learn about all its features and how to use it or have a look at the [examples](#examples) below.

In order to make `yon` available in all new terminals by default, add the above source command to your `.bashrc` file:
```sh
# file $HOME/.bashrc

if [ -f /path/to/yon.sh ]; then
  source /path/to/yon.sh
fi
```

## Examples

1. basic usage
   ```sh
   >$ yon Yes or No?
   Yes or No? [y/n]: y
   >$ echo $?
   0
   >$ echo $YON
   y
   ```
2. default answer
   ```sh
   >$ yon --default=yes Yes or No?
   Yes or No? [Y/n]:
   >$ echo $?
   0
   >$ echo $YON
   y
   ```
3. five second timeout
   ```sh
   >$ yon --timeout=5 Yes or No?
   Yes or No? [y/n]:
   >$ echo $?
   2
   ```
4. three attempts
   ```sh
   >$ yon --attempts=3 Yes or No?
   Yes or No? [y/n]: x
   Yes or No? [y/n]: ?
   Yes or No? [y/n]: *
   >$ echo $?
   3
   ```
5. custom return variable
   ```sh
   >$ yon --return-variable=myvar Yes or No?
   Yes or No? [y/n]: y
   >$ echo $?
   0
   >$ echo $YON
   y
   >$ echo $myvar
   y
   ```
6. three attempts with five second timeout, custom return variable and default answer, which is assumed on timeout
   ```sh
   >$ yon --default=yes --timeout=5 --attempts=3 --return-variable=myvar --default-on-timeout -- Yes or No?
   Yes or No? [Y/n]: x
   Yes or No? [Y/n]: ?
   Yes or No? [Y/n]:
   >$ echo $?
   0
   >$ echo $YON
   y
   >$ echo $myvar
   y
   ```

## License

`yon` is licensed under the MIT License __with Exception__.
Please refer to the [license file](./LICENSE) for further information.
