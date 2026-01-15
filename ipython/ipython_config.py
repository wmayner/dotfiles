# IPython configuration

c = get_config()

# Extensions
c.InteractiveShellApp.extensions = ['autoreload']
c.InteractiveShellApp.exec_lines = ['%autoreload 2']

# Vi mode
c.TerminalInteractiveShell.editing_mode = 'vi'
c.TerminalInteractiveShell.editor = 'vim'

# Display assigned values (e.g., `x = 5` shows 5)
c.InteractiveShell.ast_node_interactivity = 'last_expr_or_assign'

# 24-bit color support
c.TerminalInteractiveShell.true_color = True
