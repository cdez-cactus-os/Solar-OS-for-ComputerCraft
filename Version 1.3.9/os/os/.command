term.setBackgroundColor(colors.black)
term.setTextColor(colors.orange)
term.clear()
term.setCursorPos(1,1)
print("Welcome to Solar OS Command Prompt!")
term.setTextColor(colors.white)
print("To return, type 'back'.")

shell.run("rom/programs/shell")

os.run({shell = shell}, "os/.menu")
