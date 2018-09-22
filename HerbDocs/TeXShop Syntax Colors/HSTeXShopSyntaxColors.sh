#!/bin/bash
# set marker, command, comment and index colors to HS preferences
# set color of $, { and } to a medium green
defaults write TeXShop markerred 0.02
defaults write TeXShop markergreen 0.53
defaults write TeXShop markerblue 0.13
# set color of commands (\...) medium blue
defaults write TeXShop commandred 0.0
defaults write TeXShop commandgreen 0.0
defaults write TeXShop commandblue 0.8
# set color of comments to a medium gray
defaults write TeXShop commentred 0.5
defaults write TeXShop commentgreen 0.5
defaults write TeXShop commentblue 0.5
# set color of \index{...} commands to a light gray (with Color Index on)
defaults write TeXShop indexred 0.8
defaults write TeXShop indexgreen 0.8
defaults write TeXShop indexblue 0.8
