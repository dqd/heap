import XMonad
import XMonad.Prompt
import XMonad.Prompt.Shell
import XMonad.Actions.FloatKeys
import XMonad.Layout.NoBorders
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks (avoidStruts, docks)
import XMonad.Util.Run
import XMonad.Util.EZConfig (additionalKeys)
import System.IO
import System.Exit
import qualified XMonad.StackSet as W
import qualified Data.Map as M

main = do
    xmobar <- spawnPipe "xmobar"
    xmonad $ docks def
        { workspaces=map show [1..12]
        , manageHook=manageHook def <+> myManageHook
        , layoutHook=smartBorders $ avoidStruts myLayout
        , logHook=dynamicLogWithPP $ xmobarPP {ppOutput=hPutStrLn xmobar}
        , terminal="konsole"
        , keys=myKeys
        }

myManageHook :: ManageHook
myManageHook = composeAll
    [ (role =? "gimp-toolbox" <||> role =? "gimp-image-window") --> (ask >>= doF . W.sink)
    , className =? "stalonetray" --> doIgnore
    , className =? "xine" --> doFloat
    , className =? "Dia" --> doFloat
    , className =? "Vlc" --> doFloat
    , title =? "VLC media player" --> doFloat
    , title =? "VLC (XVideo output)" --> doFloat
    ] where role = stringProperty "WM_WINDOW_ROLE"

myLayout = Full ||| (Tall 1 (3/100) (1/2))

myConfig = def { font="-*-dejavu sans mono-bold-r-normal-*-12-*-*-*-*-*-*-"
               , bgColor="#111111"
               , fgColor="#FFFFFF"
               , bgHLight="#111111"
               , fgHLight="#C0C0C0"
               , promptBorderWidth=0
               , position=Top
               }

myKeys :: XConfig Layout -> M.Map (KeyMask, KeySym) (X ())
myKeys conf@(XConfig {XMonad.modMask = modMask}) = M.fromList $
    -- launching and killing programs
    [ ((modMask .|. shiftMask, xK_Return), spawn $ XMonad.terminal conf) -- %! Launch terminal
    , ((modMask,               xK_u     ), shellPrompt myConfig) -- %! Launch application
    , ((modMask .|. shiftMask, xK_c     ), kill) -- %! Close the focused window
    , ((modMask,               xK_space ), sendMessage NextLayout) -- %! Rotate through the available layout algorithms
    , ((modMask .|. shiftMask, xK_space ), setLayout $ XMonad.layoutHook conf) -- %!  Reset the layouts on the current workspace to default
    , ((modMask,               xK_n     ), refresh) -- %! Resize viewed windows to the correct size

    -- move focus up or down the window stack
    , ((modMask,               xK_Tab   ), windows W.focusDown) -- %! Move focus to the next window
    , ((modMask .|. shiftMask, xK_Tab   ), windows W.focusUp) -- %! Move focus to the previous window
    , ((modMask,               xK_j     ), windows W.focusDown) -- %! Move focus to the next window
    , ((modMask,               xK_k     ), windows W.focusUp) -- %! Move focus to the previous window
    , ((modMask,               xK_m     ), windows W.focusMaster) -- %! Move focus to the master window

    -- modifying the window order
    , ((modMask,               xK_Return), windows W.swapMaster) -- %! Swap the focused window and the master window
    , ((modMask .|. shiftMask, xK_j     ), windows W.swapDown) -- %! Swap the focused window with the next window
    , ((modMask .|. shiftMask, xK_k     ), windows W.swapUp) -- %! Swap the focused window with the previous window

    -- resizing the master/slave ratio
    , ((modMask,               xK_h     ), sendMessage Shrink) -- %! Shrink the master area
    , ((modMask,               xK_l     ), sendMessage Expand) -- %! Expand the master area
    --, ((modMask,               xK_b     ), withFocused $ keysMoveWindow (-1,-1)) -- %! fix border

    -- floating layer support
    , ((modMask,               xK_t     ), withFocused $ windows . W.sink) -- %! Push window back into tiling

    -- quit, restart
    , ((modMask .|. shiftMask, xK_q     ), io (exitWith ExitSuccess)) -- %! Quit xmonad
    , ((modMask              , xK_q     ), spawn "xmonad --recompile; xmonad --restart") -- %! Restart xmonad

    -- control of Clementine
    , ((0, xK_Print), spawn "qdbus org.mpris.MediaPlayer2.clementine /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause")
    ]
    ++ -- workspaces in screens
    [((m .|. modMask, k), windows $ f i)
        | (i, k) <- zip (XMonad.workspaces conf) [xK_F1 .. xK_F12]
        , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]]
    ++ -- switch between screens
    [((m .|. modMask, k), screenWorkspace s >>= flip whenJust (windows . f))
        | (k, s) <- zip [xK_v, xK_w] [0..]
        , (f, m) <- [(W.view, 0), (W.shift, shiftMask)]]
