""" Provides a simple command line progress bar. """
import sys


class ProgressBar(object):
    """
    class provides a simple progress bar for the command line
     use init with end_val (highest count reachable --> 100%) and
     width (width of progrssbar in number of characters) to initialiize.
     with each task done, advance it to reflect the progress on the bar.
    """
    def __init__(self, end_val, width):
        self.i = 0
        self.end_val = end_val
        self.width = width
        sys.stdout.write("|")
        sys.stdout.write("-" * width)
        sys.stdout.write("|")

    def advance(self):
        """ advances progressbar """
        self.i += 1
        percent = float(self.i) / self.end_val
        hashes = '#' * int(round(percent * self.width))
        spaces = ' ' * (self.width - len(hashes))
        sys.stdout.write("\rProgress: [{0}] {1}%".format(hashes + spaces, int(round(percent *
                                                                                    100))))
        sys.stdout.flush()
        if self.i == self.end_val:
            print("\n")
