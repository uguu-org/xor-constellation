# Toplevel Makefile for Xor Constellation project
#
# For debug builds:
#
#   make
#
# For release builds:
#
#   make release
#
# Only `pdc` from Playdate SDK is needed for these, plus a few standard
# command line tools.
#
# To refresh game data and build, do one of the following:
#
#   make -j refresh_data && make
#   make -j refresh_data && make release
#
# Refreshing game data requires a few more tools and libraries, see
# data/Makefile for more information.  At a minimum, you will likely need
# to edit data/svg_to_png.sh to set the correct path to Inkscape.

package_name=xor_constellation
data_dir=data
source_dir=source
release_source_dir=release_source

# Debug build.
$(package_name).pdx/pdxinfo: \
	$(source_dir)/data.lua \
	$(source_dir)/main.lua \
	$(source_dir)/pdxinfo
	pdc $(source_dir) $(package_name).pdx

# Release build.
release: $(package_name).zip

$(package_name).zip:
	-rm -rf $(package_name).pdx $(release_source_dir) $@
	cp -R $(source_dir) $(release_source_dir)
	rm $(release_source_dir)/data.lua
	perl $(data_dir)/inline_data.pl $(source_dir)/data.lua $(source_dir)/main.lua | perl $(data_dir)/inline_constants.pl | perl $(data_dir)/strip_lua.pl > $(release_source_dir)/main.lua
	pdc -s $(release_source_dir) $(package_name).pdx
	zip -9 -r $@ $(package_name).pdx

# Refresh data files in source directory.
refresh_data:
	$(MAKE) -C $(data_dir)
	cp -f $(data_dir)/*-table-*.png $(source_dir)/images/
	cp -f $(data_dir)/title-background.png $(source_dir)/images/
	cp -f $(data_dir)/card.png $(source_dir)/launcher/
	cp -f $(data_dir)/card_frame00.png $(source_dir)/launcher/card-highlighted/1.png
	cp -f $(data_dir)/card_frame01.png $(source_dir)/launcher/card-highlighted/2.png
	cp -f $(data_dir)/card_frame02.png $(source_dir)/launcher/card-highlighted/3.png
	cp -f $(data_dir)/card_frame03.png $(source_dir)/launcher/card-highlighted/4.png
	cp -f $(data_dir)/card_frame04.png $(source_dir)/launcher/card-highlighted/5.png
	cp -f $(data_dir)/card_frame05.png $(source_dir)/launcher/card-highlighted/6.png
	cp -f $(data_dir)/card_frame06.png $(source_dir)/launcher/card-highlighted/7.png
	cp -f $(data_dir)/card_frame07.png $(source_dir)/launcher/card-highlighted/8.png
	cp -f $(data_dir)/card_frame08.png $(source_dir)/launcher/card-highlighted/9.png
	cp -f $(data_dir)/card_frame09.png $(source_dir)/launcher/card-highlighted/10.png
	cp -f $(data_dir)/card_frame10.png $(source_dir)/launcher/card-highlighted/11.png
	cp -f $(data_dir)/card_frame11.png $(source_dir)/launcher/card-highlighted/12.png
	cp -f $(data_dir)/card_frame12.png $(source_dir)/launcher/card-highlighted/13.png
	cp -f $(data_dir)/card_frame13.png $(source_dir)/launcher/card-highlighted/14.png
	cp -f $(data_dir)/card_frame14.png $(source_dir)/launcher/card-highlighted/15.png
	cp -f $(data_dir)/card_frame15.png $(source_dir)/launcher/card-highlighted/16.png
	cp -f $(data_dir)/card_frame16.png $(source_dir)/launcher/card-highlighted/17.png
	cp -f $(data_dir)/card_frame17.png $(source_dir)/launcher/card-highlighted/18.png
	cp -f $(data_dir)/card_frame18.png $(source_dir)/launcher/card-highlighted/19.png
	cp -f $(data_dir)/card_frame19.png $(source_dir)/launcher/card-highlighted/20.png
	cp -f $(data_dir)/card_frame20.png $(source_dir)/launcher/card-highlighted/21.png
	cp -f $(data_dir)/card_frame21.png $(source_dir)/launcher/card-highlighted/22.png
	cp -f $(data_dir)/card_frame22.png $(source_dir)/launcher/card-highlighted/23.png
	cp -f $(data_dir)/card_frame23.png $(source_dir)/launcher/card-highlighted/24.png
	cp -f $(data_dir)/card_frame24.png $(source_dir)/launcher/card-highlighted/25.png
	cp -f $(data_dir)/card_frame25.png $(source_dir)/launcher/card-highlighted/26.png
	cp -f $(data_dir)/card_frame26.png $(source_dir)/launcher/card-highlighted/27.png
	cp -f $(data_dir)/card_frame27.png $(source_dir)/launcher/card-highlighted/28.png
	cp -f $(data_dir)/card_frame28.png $(source_dir)/launcher/card-highlighted/29.png
	cp -f $(data_dir)/card_frame29.png $(source_dir)/launcher/card-highlighted/30.png
	cp -f $(data_dir)/card_frame30.png $(source_dir)/launcher/card-highlighted/31.png
	cp -f $(data_dir)/card_frame31.png $(source_dir)/launcher/card-highlighted/32.png
	cp -f $(data_dir)/card_frame32.png $(source_dir)/launcher/card-highlighted/33.png
	cp -f $(data_dir)/card_frame33.png $(source_dir)/launcher/card-highlighted/34.png
	cp -f $(data_dir)/card_frame34.png $(source_dir)/launcher/card-highlighted/35.png
	cp -f $(data_dir)/card_frame35.png $(source_dir)/launcher/card-highlighted/36.png
	cp -f $(data_dir)/card_frame36.png $(source_dir)/launcher/card-highlighted/37.png
	cp -f $(data_dir)/card_frame37.png $(source_dir)/launcher/card-highlighted/38.png
	cp -f $(data_dir)/card_frame38.png $(source_dir)/launcher/card-highlighted/39.png
	cp -f $(data_dir)/card_frame39.png $(source_dir)/launcher/card-highlighted/40.png
	perl $(data_dir)/dedup_images.pl $(source_dir)/launcher/card-highlighted
	cp -f $(data_dir)/icon.png $(source_dir)/launcher/
	cp -f $(data_dir)/icon_frame00.png $(source_dir)/launcher/icon-highlighted/1.png
	cp -f $(data_dir)/icon_frame01.png $(source_dir)/launcher/icon-highlighted/2.png
	cp -f $(data_dir)/icon_frame02.png $(source_dir)/launcher/icon-highlighted/3.png
	cp -f $(data_dir)/icon_frame03.png $(source_dir)/launcher/icon-highlighted/4.png
	cp -f $(data_dir)/icon_frame04.png $(source_dir)/launcher/icon-highlighted/5.png
	cp -f $(data_dir)/icon_frame05.png $(source_dir)/launcher/icon-highlighted/6.png
	cp -f $(data_dir)/icon_frame06.png $(source_dir)/launcher/icon-highlighted/7.png
	cp -f $(data_dir)/icon_frame07.png $(source_dir)/launcher/icon-highlighted/8.png
	cp -f $(data_dir)/icon_frame08.png $(source_dir)/launcher/icon-highlighted/9.png
	cp -f $(data_dir)/icon_frame09.png $(source_dir)/launcher/icon-highlighted/10.png
	cp -f $(data_dir)/icon_frame10.png $(source_dir)/launcher/icon-highlighted/11.png
	cp -f $(data_dir)/icon_frame11.png $(source_dir)/launcher/icon-highlighted/12.png
	cp -f $(data_dir)/icon_frame12.png $(source_dir)/launcher/icon-highlighted/13.png
	cp -f $(data_dir)/icon_frame13.png $(source_dir)/launcher/icon-highlighted/14.png
	cp -f $(data_dir)/icon_frame14.png $(source_dir)/launcher/icon-highlighted/15.png
	cp -f $(data_dir)/icon_frame15.png $(source_dir)/launcher/icon-highlighted/16.png
	cp -f $(data_dir)/icon_frame16.png $(source_dir)/launcher/icon-highlighted/17.png
	cp -f $(data_dir)/icon_frame17.png $(source_dir)/launcher/icon-highlighted/18.png
	cp -f $(data_dir)/icon_frame18.png $(source_dir)/launcher/icon-highlighted/19.png
	cp -f $(data_dir)/icon_frame19.png $(source_dir)/launcher/icon-highlighted/20.png
	cp -f $(data_dir)/icon_frame20.png $(source_dir)/launcher/icon-highlighted/21.png
	cp -f $(data_dir)/icon_frame21.png $(source_dir)/launcher/icon-highlighted/22.png
	cp -f $(data_dir)/icon_frame22.png $(source_dir)/launcher/icon-highlighted/23.png
	cp -f $(data_dir)/icon_frame23.png $(source_dir)/launcher/icon-highlighted/24.png
	cp -f $(data_dir)/icon_frame24.png $(source_dir)/launcher/icon-highlighted/25.png
	cp -f $(data_dir)/icon_frame25.png $(source_dir)/launcher/icon-highlighted/26.png
	cp -f $(data_dir)/icon_frame26.png $(source_dir)/launcher/icon-highlighted/27.png
	cp -f $(data_dir)/icon_frame27.png $(source_dir)/launcher/icon-highlighted/28.png
	cp -f $(data_dir)/icon_frame28.png $(source_dir)/launcher/icon-highlighted/29.png
	cp -f $(data_dir)/icon_frame29.png $(source_dir)/launcher/icon-highlighted/30.png
	cp -f $(data_dir)/icon_frame30.png $(source_dir)/launcher/icon-highlighted/31.png
	cp -f $(data_dir)/icon_frame31.png $(source_dir)/launcher/icon-highlighted/32.png
	cp -f $(data_dir)/icon_frame32.png $(source_dir)/launcher/icon-highlighted/33.png
	cp -f $(data_dir)/icon_frame33.png $(source_dir)/launcher/icon-highlighted/34.png
	cp -f $(data_dir)/icon_frame34.png $(source_dir)/launcher/icon-highlighted/35.png
	cp -f $(data_dir)/icon_frame35.png $(source_dir)/launcher/icon-highlighted/36.png
	cp -f $(data_dir)/icon_frame36.png $(source_dir)/launcher/icon-highlighted/37.png
	cp -f $(data_dir)/icon_frame37.png $(source_dir)/launcher/icon-highlighted/38.png
	cp -f $(data_dir)/icon_frame38.png $(source_dir)/launcher/icon-highlighted/39.png
	cp -f $(data_dir)/icon_frame39.png $(source_dir)/launcher/icon-highlighted/40.png
	perl $(data_dir)/dedup_images.pl $(source_dir)/launcher/icon-highlighted
	cp -f $(data_dir)/launch.png $(source_dir)/launcher/launchImage.png
	cp -f $(data_dir)/launch.png $(source_dir)/launcher/launchImages/1.png
	cp -f $(data_dir)/*.wav $(source_dir)/sounds/
	cp -f $(data_dir)/data.lua $(source_dir)/

clean:
	$(MAKE) -C $(data_dir) clean
	-rm -rf $(package_name).pdx $(package_name).zip $(release_source_dir)
