// SlimeRunner — minimal AWT harness that runs a legacy java.applet.Applet in a
// Frame. Replaces the removed appletviewer for the ari-flash tap's Java games.
//
// Usage: java -cp <harness.jar>:<game dir> SlimeRunner \
//          --class WorldCupSoccerSlime --width 700 --height 350 --title "Slime Soccer"
//
// Compiled with --release 8 so any JRE 8+ runs it. The pinned runtime is
// Temurin 17 installed by the ari-flash-jre cask: the games call Thread.stop()
// (hard-throws UnsupportedOperationException on JDK 20+), so the JRE must be
// <= 19 and >= 8.
import java.applet.Applet;
import java.applet.AppletContext;
import java.applet.AppletStub;
import java.applet.AudioClip;
import java.awt.Dimension;
import java.awt.Frame;
import java.awt.Image;
import java.awt.Insets;
import java.awt.Toolkit;
import java.awt.event.WindowAdapter;
import java.awt.event.WindowEvent;
import java.io.InputStream;
import java.net.URL;
import java.util.Collections;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;

public final class SlimeRunner implements AppletStub, AppletContext {
    private final Map<String, String> params;
    private Applet applet;

    private SlimeRunner(Map<String, String> params) {
        this.params = params;
    }

    public static void main(String[] argv) throws Exception {
        Map<String, String> args = new HashMap<String, String>();
        Map<String, String> params = new HashMap<String, String>();
        for (int i = 0; i + 1 < argv.length; i += 2) {
            String k = argv[i];
            if (!k.startsWith("--")) { usage(); return; }
            if (k.startsWith("--param-")) {
                params.put(k.substring("--param-".length()).toLowerCase(), argv[i + 1]);
            } else {
                args.put(k.substring(2), argv[i + 1]);
            }
        }
        String cls = args.get("class");
        if (cls == null) { usage(); return; }
        if (cls.endsWith(".class")) cls = cls.substring(0, cls.length() - ".class".length());
        int width = Integer.parseInt(args.containsKey("width") ? args.get("width") : "640");
        int height = Integer.parseInt(args.containsKey("height") ? args.get("height") : "480");
        String title = args.containsKey("title") ? args.get("title") : cls;

        if ("resolve".equals(args.get("mode"))) {
            // Headless CI/dev-machine smoke: prove the class loads and is an
            // Applet without touching the display.
            Class<?> c = Class.forName(cls);
            if (!Applet.class.isAssignableFrom(c)) {
                System.err.println("not a java.applet.Applet subclass: " + cls);
                System.exit(1);
            }
            System.out.println("resolve OK: " + c.getName());
            return;
        }

        SlimeRunner stub = new SlimeRunner(params);
        final Applet applet = (Applet) Class.forName(cls).getDeclaredConstructor().newInstance();
        stub.applet = applet;
        applet.setStub(stub);

        final Frame frame = new Frame(title);
        frame.setResizable(false);
        frame.add(applet);
        applet.setPreferredSize(new Dimension(width, height));
        frame.pack();
        Insets in = frame.getInsets();
        frame.setSize(width + in.left + in.right, height + in.top + in.bottom);
        frame.setLocationRelativeTo(null);
        frame.addWindowListener(new WindowAdapter() {
            @Override public void windowClosing(WindowEvent e) {
                try { applet.stop(); applet.destroy(); } catch (Throwable ignored) {}
                frame.dispose();
                System.exit(0);
            }
            // Regain the keyboard after cmd-tab: the games use the JDK-1.0
            // keyDown model and never re-request focus themselves.
            @Override public void windowActivated(WindowEvent e) {
                applet.requestFocus();
            }
        });

        applet.init();
        frame.setVisible(true);
        applet.start();
        // Old applets read the keyboard via the applet's own focus.
        frame.toFront();
        java.awt.EventQueue.invokeLater(() -> applet.requestFocus());
    }

    private static void usage() {
        System.err.println("usage: SlimeRunner --class <AppletSubclass> [--width N] [--height N]"
                + " [--title T] [--param-<name> <value>] [--mode resolve]");
        System.exit(2);
    }

    // ---- AppletStub ----
    @Override public boolean isActive() { return true; }
    @Override public URL getDocumentBase() { return getCodeBase(); }
    @Override public URL getCodeBase() {
        try { return new java.io.File(".").toURI().toURL(); }
        catch (Exception e) { throw new RuntimeException(e); }
    }
    @Override public String getParameter(String name) {
        return params.get(name == null ? null : name.toLowerCase());
    }
    @Override public AppletContext getAppletContext() { return this; }
    @Override public void appletResize(int width, int height) { /* fixed-size frame */ }

    // ---- AppletContext ----
    @Override public AudioClip getAudioClip(URL url) { return Applet.newAudioClip(url); }
    @Override public Image getImage(URL url) { return Toolkit.getDefaultToolkit().getImage(url); }
    @Override public Applet getApplet(String name) { return null; }
    @Override public Enumeration<Applet> getApplets() {
        return Collections.enumeration(Collections.singleton(applet));
    }
    @Override public void showDocument(URL url) { /* no browser */ }
    @Override public void showDocument(URL url, String target) { /* no browser */ }
    @Override public void showStatus(String status) { /* no status bar */ }
    @Override public void setStream(String key, InputStream stream) { /* unused */ }
    @Override public InputStream getStream(String key) { return null; }
    @Override public Iterator<String> getStreamKeys() {
        return Collections.<String>emptyList().iterator();
    }
}
