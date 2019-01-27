#include <gtk/gtk.h>

int main(int argc, char *argv[], char *envp[]) {
    gtk_init(&argc, &argv);

    GdkModifierType button_state;
    gdk_window_get_pointer(NULL, NULL, NULL, &button_state);

    if (button_state & GDK_SHIFT_MASK) {
        execvp("vivaldi-stable", argv);
    } else {
        char *args[argc + 1];

        for (int i = 0; i < argc; i++) {
            args[i] = argv[i];
        }

        args[argc] = "--incognito";

        execvp("vivaldi-stable", args);
    }
}
