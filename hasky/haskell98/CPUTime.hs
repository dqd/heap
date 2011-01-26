module CPUTime where
import Prelude

foreign import ccall unsafe getCPUTime :: IO Integer
foreign import ccall unsafe cpuTimePrecision :: Integer
