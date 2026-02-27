#include <gtk/gtk.h>

int main(int argc, char *argv[], char *envp[]) {
    gtk_init(&argc, &argv);

    GdkModifierType button_state;
    gdk_window_get_pointer(NULL, NULL, NULL, &button_state);

    char *args[argc + 2];

    for (int i = 0; i < argc; i++) {
        args[i] = argv[i];
    }

    args[argc] = "--password-store=gnome-libsecret";

    if (!(button_state & GDK_SHIFT_MASK)) {
        args[argc + 1] = "--incognito";
    }

    execvp("vivaldi-stable", args);
}
