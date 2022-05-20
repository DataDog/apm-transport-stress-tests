using System.Diagnostics;
using System.Diagnostics.CodeAnalysis;
using System.Runtime.CompilerServices;

namespace MockAgent
{
    internal class DatadogHttpRequestException : Exception
    {
        public DatadogHttpRequestException(string message)
            : base(message)
        {
        }

        [MethodImpl(MethodImplOptions.NoInlining)]
        [DebuggerHidden]
        [DoesNotReturn]
        public static void Throw(string message)
        {
            throw new DatadogHttpRequestException(message);
        }
    }
}
