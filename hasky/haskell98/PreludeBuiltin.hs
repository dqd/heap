module PreludeBuiltin where

foreign import ccall unsafe primIntToChar   :: Int -> Char
foreign import ccall unsafe primCharToInt   :: Char -> Int
foreign import ccall unsafe primInteger2Int :: Integer -> Int
foreign import ccall unsafe primUnicodeMaxChar :: Char -- = '\xffff'

foreign import ccall unsafe primIntEq       :: Int -> Int -> Bool
foreign import ccall unsafe primIntLte      :: Int -> Int -> Bool

foreign import ccall unsafe primIntAdd      :: Int -> Int -> Int
foreign import ccall unsafe primIntSub      :: Int -> Int -> Int
foreign import ccall unsafe primIntMul      :: Int -> Int -> Int
foreign import ccall unsafe primIntQuot     :: Int -> Int -> Int
foreign import ccall unsafe primIntRem      :: Int -> Int -> Int
foreign import ccall unsafe primIntNegate   :: Int -> Int
foreign import ccall unsafe primIntAbs      :: Int -> Int
foreign import ccall unsafe primIntSignum   :: Int -> Int

foreign import ccall unsafe primError       :: String -> a

foreign import ccall unsafe primSeq         :: a -> b -> b

primIntQuotRem x y = (x `primIntQuot` y,x `primIntRem` y)

primCharEq c c' = primCharToInt c `primIntEq` primCharToInt c'
primCharLte c c' = primCharToInt c `primIntLte` primCharToInt c'

foreign import ccall unsafe primInteger2Int     :: Integer -> Int
foreign import ccall unsafe primInt2Integer     :: Int -> Integer

foreign import ccall unsafe primIntegerLte      :: Integer -> Integer -> Bool
foreign import ccall unsafe primIntegerEq       :: Integer -> Integer -> Bool

foreign import ccall unsafe primIntegerAdd      :: Integer -> Integer -> Integer
foreign import ccall unsafe primIntegerSub      :: Integer -> Integer -> Integer
foreign import ccall unsafe primIntegerMul      :: Integer -> Integer -> Integer
foreign import ccall unsafe primIntegerQuot     :: Integer -> Integer -> Integer
foreign import ccall unsafe primIntegerRem      :: Integer -> Integer -> Integer
foreign import ccall unsafe primIntegerNegate   :: Integer -> Integer
foreign import ccall unsafe primIntegerAbs      :: Integer -> Integer
foreign import ccall unsafe primIntegerSignum   :: Integer -> Integer
