{ dmenu, i3status }:

''
    set $mod Mod4

    font pango:Montserrat Bold 12
    title_align center

    # Use Mouse+$mod to drag floating windows to their wanted position
    floating_modifier $mod

    # start a terminal
    bindsym $mod+Return exec termite

    # kill focused window
    bindsym $mod+Shift+q kill

    # start dmenu (a program launcher)
    bindsym $mod+d exec "rofi -combi-modi window,drun,ssh -show combi"

    # change focus
    bindsym $mod+j focus left
    bindsym $mod+k focus down
    bindsym $mod+l focus up
    bindsym $mod+semicolon focus right

    # alternatively, you can use the cursor keys:
    bindsym $mod+Left focus left
    bindsym $mod+Down focus down
    bindsym $mod+Up focus up
    bindsym $mod+Right focus right

    # move focused window
    bindsym $mod+Shift+l exec "i3lock-fancy -g"

    # alternatively, you can use the cursor keys:
    bindsym $mod+Shift+Left move left
    bindsym $mod+Shift+Down move down
    bindsym $mod+Shift+Up move up
    bindsym $mod+Shift+Right move right

    # split in horizontal orientation
    bindsym $mod+h split h

    # split in vertical orientation
    bindsym $mod+v split v

    # enter fullscreen mode for the focused container
    bindsym $mod+f fullscreen

    # change container layout (stacked, tabbed, toggle split)
    bindsym $mod+s layout stacking
    bindsym $mod+w layout tabbed
    bindsym $mod+e layout toggle split

    # toggle tiling / floating
    bindsym $mod+space floating toggle

    # change focus between tiling / floating windows
    bindsym $mod+Shift+space focus mode_toggle

    # focus the parent container
    bindsym $mod+a focus parent

    # focus the child container
    #bindsym $mod+d focus child

    # switch to workspace
    bindsym $mod+1 workspace 1
    bindsym $mod+2 workspace 2
    bindsym $mod+3 workspace 3
    bindsym $mod+4 workspace 4
    bindsym $mod+5 workspace 5
    bindsym $mod+6 workspace 6
    bindsym $mod+7 workspace 7
    bindsym $mod+8 workspace 8
    bindsym $mod+9 workspace 9
    bindsym $mod+0 workspace 10

    # move focused container to workspace
    bindsym $mod+Shift+1 move container to workspace 1
    bindsym $mod+Shift+2 move container to workspace 2
    bindsym $mod+Shift+3 move container to workspace 3
    bindsym $mod+Shift+4 move container to workspace 4
    bindsym $mod+Shift+5 move container to workspace 5
    bindsym $mod+Shift+6 move container to workspace 6
    bindsym $mod+Shift+7 move container to workspace 7
    bindsym $mod+Shift+8 move container to workspace 8
    bindsym $mod+Shift+9 move container to workspace 9
    bindsym $mod+Shift+0 move container to workspace 10

    # reload the configuration file
    bindsym $mod+Shift+c reload
    # restart i3 inplace (preserves your layout/session, can be used to upgrade i3)
    bindsym $mod+Shift+r restart
    # exit i3 (logs you out of your X session)
    bindsym $mod+Shift+e exec "i3-nagbar -t warning -m 'You pressed the exit shortcut. Do you really want to exit i3? This will end your X session.' -b 'Yes, exit i3' 'i3-msg exit'"

    bindsym XF86MonBrightnessUp exec xbacklight -inc 10  # increase screen brightness
    bindsym XF86MonBrightnessDown exec xbacklight -dec 10  # decrease screen brightness

    # resize window (you can also use the mouse for that)
    mode "resize" {
            # These bindings trigger as soon as you enter the resize mode

            # Pressing left will shrink the window’s width.
            # Pressing right will grow the window’s width.
            # Pressing up will shrink the window’s height.
            # Pressing down will grow the window’s height.
            bindsym j resize shrink width 10 px or 10 ppt
            bindsym k resize grow height 10 px or 10 ppt
            bindsym l resize shrink height 10 px or 10 ppt
            bindsym semicolon resize grow width 10 px or 10 ppt

            # same bindings, but for the arrow keys
            bindsym Left resize shrink width 10 px or 10 ppt
            bindsym Down resize grow height 10 px or 10 ppt
            bindsym Up resize shrink height 10 px or 10 ppt
            bindsym Right resize grow width 10 px or 10 ppt

            # back to normal: Enter or Escape
            bindsym Return mode "default"
            bindsym Escape mode "default"
    }

    bindsym $mod+r mode "resize"

    # class                 border  bground text    indicator child_border
    client.focused          #DD8500 #DD8500 #FFFFFF #DD8500   #875100
    client.focused_inactive #5F676A #5F676A #FFFFFF #5F676A   #545B5E
    client.unfocused        #000000 #000000 #888888 #000000   #222222
    client.urgent           #2F34q3A #900000 #FFFFFF #900000   #900000
    client.placeholder      #000000 #000000 #FFFFFF #000000   #000000

    client.background       #FFFFFF

    for_window [class="^Steam$" title="^Friends$"] floating enable
    for_window [class="^Steam$" title="Steam - News"] floating enable
    for_window [class="^Steam$" title=".* - Chat"] floating enable
    for_window [class="^Steam$" title="^Settings$"] floating enable
    for_window [class="^Steam$" title=".* - event started"] floating enable
    for_window [class="^Steam$" title=".* CD key"] floating enable
    for_window [class="^Steam$" title="^Steam - Self Updater$"] floating enable
    for_window [class="^Steam$" title="^Screenshot Uploader$"] floating enable
    for_window [class="^Steam$" title="^Steam Guard - Computer Authorization Required$"] floating enable
    for_window [title="^Steam Keyboard$"] floating enable

  # Jetbrains
  for_window [class="^com-intellij-updater-Runner$" title="^Update$"] floating enable
  for_window [instance="^sun-awt-X11-XDialogPeer$" title="^Complete Installation$"] floating enable

  for_window [class=".*"] border pixel 0
  exec --no-startup-id nitrogen --restore

  gaps inner all set 20
''