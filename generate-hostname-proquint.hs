#!/usr/bin/env nix-shell
#!nix-shell --pure -i runghc -p "haskellPackages.ghcWithPackages (pkgs: [ pkgs.proquint pkgs.maccatcher ])"

-- {-# LANGUAGE Safe #-}

-- import System.Info (os)
-- import Network.System.Net (getInterfaceInfo)
import System.Info.MAC (mac)

main :: IO ()
main = do
  mac_addr <- mac
  case mac_addr of
    Just addr -> putStrLn $ "MAC Address : " ++ show addr
    Nothing   -> putStrLn "Could not get MAC address"
