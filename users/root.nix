{ config, lib, pkgs, ... }: { 
	users.users.root = { 
            shell = pkgs.zsh; 
            openssh.authorizedKeys.keys = config.users.users.thilo.openssh.authorizedKeys.keys;
    }; 
}
