# vim:fileencoding=utf-8:noet

import re

from powerline.lib.unicode import u
from powerline.theme import requires_segment_info


@requires_segment_info
def full_path(pl, segment_info):
    """Returns a segment containing the full path of the current working
    directory."""
    try:
        cwd = u(segment_info['getcwd']())
    except OSError as e:
        if e.errno == 2:
            # user most probably deleted the directory
            # this happens when removing files from Mercurial repos for example
            pl.warn('Current directory not found')
            cwd = "[not found]"
        else:
            raise
    home = segment_info['home']
    if home:
        home = u(home)
        cwd = re.sub('^' + re.escape(home), '~', cwd, 1)
    return cwd
