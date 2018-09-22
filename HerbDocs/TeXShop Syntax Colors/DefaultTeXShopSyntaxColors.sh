#!/bin/bash
# set marker, command, comment and index colors to Default preferences
# set color of $, { and } to a darker green
defaults write TeXShop markerred 0.02
defaults write TeXShop markergreen 0.51
defaults write TeXShop markerblue 0.13
# set color of commands (\...) solid blue
defaults write TeXShop commandred 0.0
defaults write TeXShop commandgreen 0.0
defaults write TeXShop commandblue 1.0
# set color of comments to a solid red
defaults write TeXShop commentred 1.0
defaults write TeXShop commentgreen 0.0
defaults write TeXShop commentblue 0.0
# set color of \index{...} commands to a bright yellow (with Color Index on)
defaults write TeXShop indexred 1.0
defaults write TeXShop indexgreen 1.0
defaults write TeXShop indexblue 0.0
