import datadog.trace.api.Trace;

public class Spammer {
    public static void main(String[] args) {
        
        Tracer tracer = GlobalTracer.get();    
        System.out.println("Tracer found of type " + tracer.getClass().toString());
        System.out.println("Sleeping for 10 seconds to wait for agent");
        Thread.sleep(10000);
        System.out.println("Starting spammer");
        
        while (true) {
            makeSpan()
            Thread.sleep(1);
        }
        
        System.out.println("Ending spammer");
    }
    
    @Trace(operationName = "spam", resourceName = "spammer")
    public static void makeSpan() {
        innerSpan();
    }
    
    @Trace(operationName = "nested-spam")
    public static void innerSpan() {
        Thread.sleep(1);
    }
}