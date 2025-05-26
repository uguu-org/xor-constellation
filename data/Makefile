# Build images, sounds and other supporting data.  Takes ~3 minutes to build
# and costs ~5M of disk space.
#
# Requires gcc, perl, ruby, netpbm, ImageMagick, Inkscape, and ffmpeg.
# gcc also needs libpng, and perl needs libxml.
#
# See svg_to_png.sh for more details on Inkscape.

targets = \
	large-digit-table-20-32.png \
	small-digit-table-8-13.png \
	dots-table-26-6.png \
	sprite-table-96-64.png \
	stars-table-32-32.png \
	modes-table-61-44.png \
	title-char-table-194-74.png \
	title-background.png \
	card.png \
	card_frame00.png \
	card_frame01.png \
	card_frame02.png \
	card_frame03.png \
	card_frame04.png \
	card_frame05.png \
	card_frame06.png \
	card_frame07.png \
	card_frame08.png \
	card_frame09.png \
	card_frame10.png \
	card_frame11.png \
	card_frame12.png \
	card_frame13.png \
	card_frame14.png \
	card_frame15.png \
	card_frame16.png \
	card_frame17.png \
	card_frame18.png \
	card_frame19.png \
	card_frame20.png \
	card_frame21.png \
	card_frame22.png \
	card_frame23.png \
	card_frame24.png \
	card_frame25.png \
	card_frame26.png \
	card_frame27.png \
	card_frame28.png \
	card_frame29.png \
	card_frame30.png \
	card_frame31.png \
	card_frame32.png \
	card_frame33.png \
	card_frame34.png \
	card_frame35.png \
	card_frame36.png \
	card_frame37.png \
	card_frame38.png \
	card_frame39.png \
	icon.png \
	icon_frame00.png \
	icon_frame01.png \
	icon_frame02.png \
	icon_frame03.png \
	icon_frame04.png \
	icon_frame05.png \
	icon_frame06.png \
	icon_frame07.png \
	icon_frame08.png \
	icon_frame09.png \
	icon_frame10.png \
	icon_frame11.png \
	icon_frame12.png \
	icon_frame13.png \
	icon_frame14.png \
	icon_frame15.png \
	icon_frame16.png \
	icon_frame17.png \
	icon_frame18.png \
	icon_frame19.png \
	icon_frame20.png \
	icon_frame21.png \
	icon_frame22.png \
	icon_frame23.png \
	icon_frame24.png \
	icon_frame25.png \
	icon_frame26.png \
	icon_frame27.png \
	icon_frame28.png \
	icon_frame29.png \
	icon_frame30.png \
	icon_frame31.png \
	icon_frame32.png \
	icon_frame33.png \
	icon_frame34.png \
	icon_frame35.png \
	icon_frame36.png \
	icon_frame37.png \
	icon_frame38.png \
	icon_frame39.png \
	launch.png \
	celesta.wav \
	data.lua \
	itch_cover.png

# Common compiler flags for C/C++ tools.
#
# "-march=native -O3" produces the fastest executables, although these flags
# are here mostly for readability.  For any particular executable, most of
# the time will be spent inside the pre-compiled libpng, and the overall
# build time will be dominated by Inkscape.
cflags = -march=native -O3 -Wall -Wextra -pedantic

# Crop region inside world.svg for title text.  This needs to match the
# dimensions encoded in title-char-table filename.
title_text_x1 = 871
title_text_y1 = 50
title_text_x2 = 1065
title_text_y2 = 124


# ......................................................................
# {{{ Primary build artifacts.

all: $(targets)

large-digit-table-20-32.png: t_large_digits.png optimize_png.pl
	perl optimize_png.pl $< > $@

small-digit-table-8-13.png: t_small_digits.png optimize_png.pl
	perl optimize_png.pl $< > $@

dots-table-26-6.png: t_dots.png optimize_png.pl
	perl optimize_png.pl $< > $@

sprite-table-96-64.png: t_sprites.png optimize_png.pl
	perl optimize_png.pl $< > $@

stars-table-32-32.png: t_stars.png optimize_png.pl
	perl optimize_png.pl $< > $@

modes-table-61-44.png: t_modes_table.png optimize_png.pl
	perl optimize_png.pl $< > $@

title-background.png: t_title_background.png optimize_png.pl
	perl optimize_png.pl $< > $@

title-char-table-194-74.png: t_title_char_table.png optimize_png.pl
	perl optimize_png.pl $< > $@

card.png: t_card.png optimize_png.pl
	perl optimize_png.pl $< > $@

card_frame00.png: t_card_frame00.png optimize_png.pl
	perl optimize_png.pl $< > $@

card_frame01.png: t_card_frame01.png optimize_png.pl
	perl optimize_png.pl $< > $@

card_frame02.png: t_card_frame02.png optimize_png.pl
	perl optimize_png.pl $< > $@

card_frame03.png: t_card_frame03.png optimize_png.pl
	perl optimize_png.pl $< > $@

card_frame04.png: t_card_frame04.png optimize_png.pl
	perl optimize_png.pl $< > $@

card_frame05.png: t_card_frame05.png optimize_png.pl
	perl optimize_png.pl $< > $@

card_frame06.png: t_card_frame06.png optimize_png.pl
	perl optimize_png.pl $< > $@

card_frame07.png: t_card_frame07.png optimize_png.pl
	perl optimize_png.pl $< > $@

card_frame08.png: t_card_frame08.png optimize_png.pl
	perl optimize_png.pl $< > $@

card_frame09.png: t_card_frame09.png optimize_png.pl
	perl optimize_png.pl $< > $@

card_frame10.png: t_card_frame10.png optimize_png.pl
	perl optimize_png.pl $< > $@

card_frame11.png: t_card_frame11.png optimize_png.pl
	perl optimize_png.pl $< > $@

card_frame12.png: t_card_frame12.png optimize_png.pl
	perl optimize_png.pl $< > $@

card_frame13.png: t_card_frame13.png optimize_png.pl
	perl optimize_png.pl $< > $@

card_frame14.png: t_card_frame14.png optimize_png.pl
	perl optimize_png.pl $< > $@

card_frame15.png: t_card_frame15.png optimize_png.pl
	perl optimize_png.pl $< > $@

card_frame16.png: t_card_frame16.png optimize_png.pl
	perl optimize_png.pl $< > $@

card_frame17.png: t_card_frame17.png optimize_png.pl
	perl optimize_png.pl $< > $@

card_frame18.png: t_card_frame18.png optimize_png.pl
	perl optimize_png.pl $< > $@

card_frame19.png: t_card_frame19.png optimize_png.pl
	perl optimize_png.pl $< > $@

card_frame20.png: t_card_frame20.png optimize_png.pl
	perl optimize_png.pl $< > $@

card_frame21.png: t_card_frame21.png optimize_png.pl
	perl optimize_png.pl $< > $@

card_frame22.png: t_card_frame22.png optimize_png.pl
	perl optimize_png.pl $< > $@

card_frame23.png: t_card_frame23.png optimize_png.pl
	perl optimize_png.pl $< > $@

card_frame24.png: t_card_frame24.png optimize_png.pl
	perl optimize_png.pl $< > $@

card_frame25.png: t_card_frame25.png optimize_png.pl
	perl optimize_png.pl $< > $@

card_frame26.png: t_card_frame26.png optimize_png.pl
	perl optimize_png.pl $< > $@

card_frame27.png: t_card_frame27.png optimize_png.pl
	perl optimize_png.pl $< > $@

card_frame28.png: t_card_frame28.png optimize_png.pl
	perl optimize_png.pl $< > $@

card_frame29.png: t_card_frame29.png optimize_png.pl
	perl optimize_png.pl $< > $@

card_frame30.png: t_card_frame30.png optimize_png.pl
	perl optimize_png.pl $< > $@

card_frame31.png: t_card_frame31.png optimize_png.pl
	perl optimize_png.pl $< > $@

card_frame32.png: t_card_frame32.png optimize_png.pl
	perl optimize_png.pl $< > $@

card_frame33.png: t_card_frame33.png optimize_png.pl
	perl optimize_png.pl $< > $@

card_frame34.png: t_card_frame34.png optimize_png.pl
	perl optimize_png.pl $< > $@

card_frame35.png: t_card_frame35.png optimize_png.pl
	perl optimize_png.pl $< > $@

card_frame36.png: t_card_frame36.png optimize_png.pl
	perl optimize_png.pl $< > $@

card_frame37.png: t_card_frame37.png optimize_png.pl
	perl optimize_png.pl $< > $@

card_frame38.png: t_card_frame38.png optimize_png.pl
	perl optimize_png.pl $< > $@

card_frame39.png: t_card_frame39.png optimize_png.pl
	perl optimize_png.pl $< > $@

icon.png: t_icon.png optimize_png.pl
	perl optimize_png.pl $< > $@

icon_frame00.png: t_icon_frame00.png optimize_png.pl
	perl optimize_png.pl $< > $@

icon_frame01.png: t_icon_frame01.png optimize_png.pl
	perl optimize_png.pl $< > $@

icon_frame02.png: t_icon_frame02.png optimize_png.pl
	perl optimize_png.pl $< > $@

icon_frame03.png: t_icon_frame03.png optimize_png.pl
	perl optimize_png.pl $< > $@

icon_frame04.png: t_icon_frame04.png optimize_png.pl
	perl optimize_png.pl $< > $@

icon_frame05.png: t_icon_frame05.png optimize_png.pl
	perl optimize_png.pl $< > $@

icon_frame06.png: t_icon_frame06.png optimize_png.pl
	perl optimize_png.pl $< > $@

icon_frame07.png: t_icon_frame07.png optimize_png.pl
	perl optimize_png.pl $< > $@

icon_frame08.png: t_icon_frame08.png optimize_png.pl
	perl optimize_png.pl $< > $@

icon_frame09.png: t_icon_frame09.png optimize_png.pl
	perl optimize_png.pl $< > $@

icon_frame10.png: t_icon_frame10.png optimize_png.pl
	perl optimize_png.pl $< > $@

icon_frame11.png: t_icon_frame11.png optimize_png.pl
	perl optimize_png.pl $< > $@

icon_frame12.png: t_icon_frame12.png optimize_png.pl
	perl optimize_png.pl $< > $@

icon_frame13.png: t_icon_frame13.png optimize_png.pl
	perl optimize_png.pl $< > $@

icon_frame14.png: t_icon_frame14.png optimize_png.pl
	perl optimize_png.pl $< > $@

icon_frame15.png: t_icon_frame15.png optimize_png.pl
	perl optimize_png.pl $< > $@

icon_frame16.png: t_icon_frame16.png optimize_png.pl
	perl optimize_png.pl $< > $@

icon_frame17.png: t_icon_frame17.png optimize_png.pl
	perl optimize_png.pl $< > $@

icon_frame18.png: t_icon_frame18.png optimize_png.pl
	perl optimize_png.pl $< > $@

icon_frame19.png: t_icon_frame19.png optimize_png.pl
	perl optimize_png.pl $< > $@

icon_frame20.png: t_icon_frame20.png optimize_png.pl
	perl optimize_png.pl $< > $@

icon_frame21.png: t_icon_frame21.png optimize_png.pl
	perl optimize_png.pl $< > $@

icon_frame22.png: t_icon_frame22.png optimize_png.pl
	perl optimize_png.pl $< > $@

icon_frame23.png: t_icon_frame23.png optimize_png.pl
	perl optimize_png.pl $< > $@

icon_frame24.png: t_icon_frame24.png optimize_png.pl
	perl optimize_png.pl $< > $@

icon_frame25.png: t_icon_frame25.png optimize_png.pl
	perl optimize_png.pl $< > $@

icon_frame26.png: t_icon_frame26.png optimize_png.pl
	perl optimize_png.pl $< > $@

icon_frame27.png: t_icon_frame27.png optimize_png.pl
	perl optimize_png.pl $< > $@

icon_frame28.png: t_icon_frame28.png optimize_png.pl
	perl optimize_png.pl $< > $@

icon_frame29.png: t_icon_frame29.png optimize_png.pl
	perl optimize_png.pl $< > $@

icon_frame30.png: t_icon_frame30.png optimize_png.pl
	perl optimize_png.pl $< > $@

icon_frame31.png: t_icon_frame31.png optimize_png.pl
	perl optimize_png.pl $< > $@

icon_frame32.png: t_icon_frame32.png optimize_png.pl
	perl optimize_png.pl $< > $@

icon_frame33.png: t_icon_frame33.png optimize_png.pl
	perl optimize_png.pl $< > $@

icon_frame34.png: t_icon_frame34.png optimize_png.pl
	perl optimize_png.pl $< > $@

icon_frame35.png: t_icon_frame35.png optimize_png.pl
	perl optimize_png.pl $< > $@

icon_frame36.png: t_icon_frame36.png optimize_png.pl
	perl optimize_png.pl $< > $@

icon_frame37.png: t_icon_frame37.png optimize_png.pl
	perl optimize_png.pl $< > $@

icon_frame38.png: t_icon_frame38.png optimize_png.pl
	perl optimize_png.pl $< > $@

icon_frame39.png: t_icon_frame39.png optimize_png.pl
	perl optimize_png.pl $< > $@

launch.png: t_launch.png optimize_png.pl
	perl optimize_png.pl $< > $@

celesta.wav: sounds/celesta.wav
	ffmpeg -loglevel fatal -i $< -t 0:01.00 -ar 44100 -acodec pcm_s16le -y $@

data.lua: t_rates.lua t_note_groups.lua t_cursor_poly.lua t_drift_offsets.lua t_permutations6.lua t_bit_table.lua
	cat $^ > $@

itch_cover.png: t_itch_cover.png optimize_png.pl
	perl optimize_png.pl $< > $@

# }}}

# ......................................................................
# {{{ Launcher images.

t_title_all_chars.png: \
	stack_bw.exe \
	t_title_char_0.png \
	t_title_char_1.png \
	t_title_char_2.png \
	t_title_char_3.png \
	t_title_char_4.png \
	t_title_char_5.png \
	t_title_char_6.png \
	t_title_char_7.png \
	t_title_char_8.png \
	t_title_char_9.png \
	t_title_char_a.png \
	t_title_char_b.png \
	t_title_char_c.png \
	t_title_char_d.png \
	t_title_char_e.png \
	t_title_char_f.png
	./$^ > $@

t_title_striped_chars.png: t_title_all_chars.png horizontal_stripes.exe
	./horizontal_stripes.exe < $< > $@

t_title_flash_0.png: \
	stack_bw.exe \
	t_title_striped_chars.png \
	t_title_char_1.png \
	t_title_char_2.png \
	t_title_char_3.png \
	t_title_char_4.png \
	t_title_char_5.png \
	t_title_char_6.png \
	t_title_char_7.png \
	t_title_char_8.png \
	t_title_char_9.png \
	t_title_char_a.png \
	t_title_char_b.png \
	t_title_char_c.png \
	t_title_char_d.png \
	t_title_char_e.png \
	t_title_char_f.png
	./$^ > $@

t_title_flash_1.png: \
	stack_bw.exe \
	t_title_striped_chars.png \
	t_title_char_0.png \
	t_title_char_2.png \
	t_title_char_3.png \
	t_title_char_4.png \
	t_title_char_5.png \
	t_title_char_6.png \
	t_title_char_7.png \
	t_title_char_8.png \
	t_title_char_9.png \
	t_title_char_a.png \
	t_title_char_b.png \
	t_title_char_c.png \
	t_title_char_d.png \
	t_title_char_e.png \
	t_title_char_f.png
	./$^ > $@

t_title_flash_2.png: \
	stack_bw.exe \
	t_title_striped_chars.png \
	t_title_char_0.png \
	t_title_char_1.png \
	t_title_char_3.png \
	t_title_char_4.png \
	t_title_char_5.png \
	t_title_char_6.png \
	t_title_char_7.png \
	t_title_char_8.png \
	t_title_char_9.png \
	t_title_char_a.png \
	t_title_char_b.png \
	t_title_char_c.png \
	t_title_char_d.png \
	t_title_char_e.png \
	t_title_char_f.png
	./$^ > $@

t_title_flash_3.png: \
	stack_bw.exe \
	t_title_striped_chars.png \
	t_title_char_0.png \
	t_title_char_1.png \
	t_title_char_2.png \
	t_title_char_4.png \
	t_title_char_5.png \
	t_title_char_6.png \
	t_title_char_7.png \
	t_title_char_8.png \
	t_title_char_9.png \
	t_title_char_a.png \
	t_title_char_b.png \
	t_title_char_c.png \
	t_title_char_d.png \
	t_title_char_e.png \
	t_title_char_f.png
	./$^ > $@

t_title_flash_4.png: \
	stack_bw.exe \
	t_title_striped_chars.png \
	t_title_char_0.png \
	t_title_char_1.png \
	t_title_char_2.png \
	t_title_char_3.png \
	t_title_char_5.png \
	t_title_char_6.png \
	t_title_char_7.png \
	t_title_char_8.png \
	t_title_char_9.png \
	t_title_char_a.png \
	t_title_char_b.png \
	t_title_char_c.png \
	t_title_char_d.png \
	t_title_char_e.png \
	t_title_char_f.png
	./$^ > $@

t_title_flash_5.png: \
	stack_bw.exe \
	t_title_striped_chars.png \
	t_title_char_0.png \
	t_title_char_1.png \
	t_title_char_2.png \
	t_title_char_3.png \
	t_title_char_4.png \
	t_title_char_6.png \
	t_title_char_7.png \
	t_title_char_8.png \
	t_title_char_9.png \
	t_title_char_a.png \
	t_title_char_b.png \
	t_title_char_c.png \
	t_title_char_d.png \
	t_title_char_e.png \
	t_title_char_f.png
	./$^ > $@

t_title_flash_6.png: \
	stack_bw.exe \
	t_title_striped_chars.png \
	t_title_char_0.png \
	t_title_char_1.png \
	t_title_char_2.png \
	t_title_char_3.png \
	t_title_char_4.png \
	t_title_char_5.png \
	t_title_char_7.png \
	t_title_char_8.png \
	t_title_char_9.png \
	t_title_char_a.png \
	t_title_char_b.png \
	t_title_char_c.png \
	t_title_char_d.png \
	t_title_char_e.png \
	t_title_char_f.png
	./$^ > $@

t_title_flash_7.png: \
	stack_bw.exe \
	t_title_striped_chars.png \
	t_title_char_0.png \
	t_title_char_1.png \
	t_title_char_2.png \
	t_title_char_3.png \
	t_title_char_4.png \
	t_title_char_5.png \
	t_title_char_6.png \
	t_title_char_8.png \
	t_title_char_9.png \
	t_title_char_a.png \
	t_title_char_b.png \
	t_title_char_c.png \
	t_title_char_d.png \
	t_title_char_e.png \
	t_title_char_f.png
	./$^ > $@

t_title_flash_8.png: \
	stack_bw.exe \
	t_title_striped_chars.png \
	t_title_char_0.png \
	t_title_char_1.png \
	t_title_char_2.png \
	t_title_char_3.png \
	t_title_char_4.png \
	t_title_char_5.png \
	t_title_char_6.png \
	t_title_char_7.png \
	t_title_char_9.png \
	t_title_char_a.png \
	t_title_char_b.png \
	t_title_char_c.png \
	t_title_char_d.png \
	t_title_char_e.png \
	t_title_char_f.png
	./$^ > $@

t_title_flash_9.png: \
	stack_bw.exe \
	t_title_striped_chars.png \
	t_title_char_0.png \
	t_title_char_1.png \
	t_title_char_2.png \
	t_title_char_3.png \
	t_title_char_4.png \
	t_title_char_5.png \
	t_title_char_6.png \
	t_title_char_7.png \
	t_title_char_8.png \
	t_title_char_a.png \
	t_title_char_b.png \
	t_title_char_c.png \
	t_title_char_d.png \
	t_title_char_e.png \
	t_title_char_f.png
	./$^ > $@

t_title_flash_a.png: \
	stack_bw.exe \
	t_title_striped_chars.png \
	t_title_char_0.png \
	t_title_char_1.png \
	t_title_char_2.png \
	t_title_char_3.png \
	t_title_char_4.png \
	t_title_char_5.png \
	t_title_char_6.png \
	t_title_char_7.png \
	t_title_char_8.png \
	t_title_char_9.png \
	t_title_char_b.png \
	t_title_char_c.png \
	t_title_char_d.png \
	t_title_char_e.png \
	t_title_char_f.png
	./$^ > $@

t_title_flash_b.png: \
	stack_bw.exe \
	t_title_striped_chars.png \
	t_title_char_0.png \
	t_title_char_1.png \
	t_title_char_2.png \
	t_title_char_3.png \
	t_title_char_4.png \
	t_title_char_5.png \
	t_title_char_6.png \
	t_title_char_7.png \
	t_title_char_8.png \
	t_title_char_9.png \
	t_title_char_a.png \
	t_title_char_c.png \
	t_title_char_d.png \
	t_title_char_e.png \
	t_title_char_f.png
	./$^ > $@

t_title_flash_c.png: \
	stack_bw.exe \
	t_title_striped_chars.png \
	t_title_char_0.png \
	t_title_char_1.png \
	t_title_char_2.png \
	t_title_char_3.png \
	t_title_char_4.png \
	t_title_char_5.png \
	t_title_char_6.png \
	t_title_char_7.png \
	t_title_char_8.png \
	t_title_char_9.png \
	t_title_char_a.png \
	t_title_char_b.png \
	t_title_char_d.png \
	t_title_char_e.png \
	t_title_char_f.png
	./$^ > $@

t_title_flash_d.png: \
	stack_bw.exe \
	t_title_striped_chars.png \
	t_title_char_0.png \
	t_title_char_1.png \
	t_title_char_2.png \
	t_title_char_3.png \
	t_title_char_4.png \
	t_title_char_5.png \
	t_title_char_6.png \
	t_title_char_7.png \
	t_title_char_8.png \
	t_title_char_9.png \
	t_title_char_a.png \
	t_title_char_b.png \
	t_title_char_c.png \
	t_title_char_e.png \
	t_title_char_f.png
	./$^ > $@

t_title_flash_e.png: \
	stack_bw.exe \
	t_title_striped_chars.png \
	t_title_char_0.png \
	t_title_char_1.png \
	t_title_char_2.png \
	t_title_char_3.png \
	t_title_char_4.png \
	t_title_char_5.png \
	t_title_char_6.png \
	t_title_char_7.png \
	t_title_char_8.png \
	t_title_char_9.png \
	t_title_char_a.png \
	t_title_char_b.png \
	t_title_char_c.png \
	t_title_char_d.png \
	t_title_char_f.png
	./$^ > $@

t_title_flash_f.png: \
	stack_bw.exe \
	t_title_striped_chars.png \
	t_title_char_0.png \
	t_title_char_1.png \
	t_title_char_2.png \
	t_title_char_3.png \
	t_title_char_4.png \
	t_title_char_5.png \
	t_title_char_6.png \
	t_title_char_7.png \
	t_title_char_8.png \
	t_title_char_9.png \
	t_title_char_a.png \
	t_title_char_b.png \
	t_title_char_c.png \
	t_title_char_d.png \
	t_title_char_e.png
	./$^ > $@

t_card_all_chars.png: t_title_all_chars.png
	convert $< -background none -gravity SouthEast -extent 272x109 png:- | convert png:- -background none -gravity NorthWest -extent 350x155 $@

t_card_flash_0.png: t_title_flash_0.png
	convert $< -background none -gravity SouthEast -extent 272x109 png:- | convert png:- -background none -gravity NorthWest -extent 350x155 $@

t_card_flash_1.png: t_title_flash_1.png
	convert $< -background none -gravity SouthEast -extent 272x109 png:- | convert png:- -background none -gravity NorthWest -extent 350x155 $@

t_card_flash_2.png: t_title_flash_2.png
	convert $< -background none -gravity SouthEast -extent 272x109 png:- | convert png:- -background none -gravity NorthWest -extent 350x155 $@

t_card_flash_3.png: t_title_flash_3.png
	convert $< -background none -gravity SouthEast -extent 272x109 png:- | convert png:- -background none -gravity NorthWest -extent 350x155 $@

t_card_flash_4.png: t_title_flash_4.png
	convert $< -background none -gravity SouthEast -extent 272x109 png:- | convert png:- -background none -gravity NorthWest -extent 350x155 $@

t_card_flash_5.png: t_title_flash_5.png
	convert $< -background none -gravity SouthEast -extent 272x109 png:- | convert png:- -background none -gravity NorthWest -extent 350x155 $@

t_card_flash_6.png: t_title_flash_6.png
	convert $< -background none -gravity SouthEast -extent 272x109 png:- | convert png:- -background none -gravity NorthWest -extent 350x155 $@

t_card_flash_7.png: t_title_flash_7.png
	convert $< -background none -gravity SouthEast -extent 272x109 png:- | convert png:- -background none -gravity NorthWest -extent 350x155 $@

t_card_flash_8.png: t_title_flash_8.png
	convert $< -background none -gravity SouthEast -extent 272x109 png:- | convert png:- -background none -gravity NorthWest -extent 350x155 $@

t_card_flash_9.png: t_title_flash_9.png
	convert $< -background none -gravity SouthEast -extent 272x109 png:- | convert png:- -background none -gravity NorthWest -extent 350x155 $@

t_card_flash_a.png: t_title_flash_a.png
	convert $< -background none -gravity SouthEast -extent 272x109 png:- | convert png:- -background none -gravity NorthWest -extent 350x155 $@

t_card_flash_b.png: t_title_flash_b.png
	convert $< -background none -gravity SouthEast -extent 272x109 png:- | convert png:- -background none -gravity NorthWest -extent 350x155 $@

t_card_flash_c.png: t_title_flash_c.png
	convert $< -background none -gravity SouthEast -extent 272x109 png:- | convert png:- -background none -gravity NorthWest -extent 350x155 $@

t_card_flash_d.png: t_title_flash_d.png
	convert $< -background none -gravity SouthEast -extent 272x109 png:- | convert png:- -background none -gravity NorthWest -extent 350x155 $@

t_card_flash_e.png: t_title_flash_e.png
	convert $< -background none -gravity SouthEast -extent 272x109 png:- | convert png:- -background none -gravity NorthWest -extent 350x155 $@

t_card_flash_f.png: t_title_flash_f.png
	convert $< -background none -gravity SouthEast -extent 272x109 png:- | convert png:- -background none -gravity NorthWest -extent 350x155 $@

t_card.png: t_card_all_chars.png
	convert -size 350x155 xc:'#ffffff' -depth 8 -colorspace Gray $< -composite $@

t_card_frame00.png: t_card_all_chars.png add_starfield.exe
	./add_starfield.exe $< 0 | convert -size 350x155 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_card_frame01.png: t_card_all_chars.png add_starfield.exe
	./add_starfield.exe $< 1 | convert -size 350x155 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_card_frame02.png: t_card_all_chars.png add_starfield.exe
	./add_starfield.exe $< 2 | convert -size 350x155 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_card_frame03.png: t_card_all_chars.png add_starfield.exe
	./add_starfield.exe $< 3 | convert -size 350x155 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_card_frame04.png: t_card_all_chars.png add_starfield.exe
	./add_starfield.exe $< 4 | convert -size 350x155 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_card_frame05.png: t_card_all_chars.png add_starfield.exe
	./add_starfield.exe $< 5 | convert -size 350x155 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_card_frame06.png: t_card_all_chars.png add_starfield.exe
	./add_starfield.exe $< 6 | convert -size 350x155 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_card_frame07.png: t_card_all_chars.png add_starfield.exe
	./add_starfield.exe $< 7 | convert -size 350x155 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_card_frame08.png: t_card_all_chars.png add_starfield.exe
	./add_starfield.exe $< 8 | convert -size 350x155 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_card_frame09.png: t_card_all_chars.png add_starfield.exe
	./add_starfield.exe $< 9 | convert -size 350x155 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_card_frame10.png: t_card_all_chars.png add_starfield.exe
	./add_starfield.exe $< 10 | convert -size 350x155 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_card_frame11.png: t_card_all_chars.png add_starfield.exe
	./add_starfield.exe $< 11 | convert -size 350x155 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_card_frame12.png: t_card_all_chars.png add_starfield.exe
	./add_starfield.exe $< 12 | convert -size 350x155 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_card_frame13.png: t_card_all_chars.png add_starfield.exe
	./add_starfield.exe $< 13 | convert -size 350x155 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_card_frame14.png: t_card_all_chars.png add_starfield.exe
	./add_starfield.exe $< 14 | convert -size 350x155 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_card_frame15.png: t_card_all_chars.png add_starfield.exe
	./add_starfield.exe $< 15 | convert -size 350x155 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_card_frame16.png: t_card_all_chars.png add_starfield.exe
	./add_starfield.exe $< 16 | convert -size 350x155 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_card_frame17.png: t_card_all_chars.png add_starfield.exe
	./add_starfield.exe $< 17 | convert -size 350x155 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_card_frame18.png: t_card_all_chars.png add_starfield.exe
	./add_starfield.exe $< 18 | convert -size 350x155 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_card_frame19.png: t_card_all_chars.png add_starfield.exe
	./add_starfield.exe $< 19 | convert -size 350x155 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_card_frame20.png: t_card_all_chars.png add_starfield.exe
	./add_starfield.exe $< 20 | convert -size 350x155 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_card_frame21.png: t_card_all_chars.png add_starfield.exe
	./add_starfield.exe $< 21 | convert -size 350x155 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_card_frame22.png: t_card_all_chars.png add_starfield.exe
	./add_starfield.exe $< 22 | convert -size 350x155 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_card_frame23.png: t_card_all_chars.png add_starfield.exe
	./add_starfield.exe $< 23 | convert -size 350x155 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_card_frame24.png: t_card_flash_0.png add_starfield.exe
	./add_starfield.exe $< 24 | convert -size 350x155 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_card_frame25.png: t_card_flash_1.png add_starfield.exe
	./add_starfield.exe $< 25 | convert -size 350x155 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_card_frame26.png: t_card_flash_2.png add_starfield.exe
	./add_starfield.exe $< 26 | convert -size 350x155 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_card_frame27.png: t_card_flash_3.png add_starfield.exe
	./add_starfield.exe $< 27 | convert -size 350x155 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_card_frame28.png: t_card_flash_4.png add_starfield.exe
	./add_starfield.exe $< 28 | convert -size 350x155 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_card_frame29.png: t_card_flash_5.png add_starfield.exe
	./add_starfield.exe $< 29 | convert -size 350x155 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_card_frame30.png: t_card_flash_6.png add_starfield.exe
	./add_starfield.exe $< 30 | convert -size 350x155 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_card_frame31.png: t_card_flash_7.png add_starfield.exe
	./add_starfield.exe $< 31 | convert -size 350x155 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_card_frame32.png: t_card_flash_8.png add_starfield.exe
	./add_starfield.exe $< 32 | convert -size 350x155 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_card_frame33.png: t_card_flash_9.png add_starfield.exe
	./add_starfield.exe $< 33 | convert -size 350x155 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_card_frame34.png: t_card_flash_a.png add_starfield.exe
	./add_starfield.exe $< 34 | convert -size 350x155 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_card_frame35.png: t_card_flash_b.png add_starfield.exe
	./add_starfield.exe $< 35 | convert -size 350x155 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_card_frame36.png: t_card_flash_c.png add_starfield.exe
	./add_starfield.exe $< 36 | convert -size 350x155 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_card_frame37.png: t_card_flash_d.png add_starfield.exe
	./add_starfield.exe $< 37 | convert -size 350x155 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_card_frame38.png: t_card_flash_e.png add_starfield.exe
	./add_starfield.exe $< 38 | convert -size 350x155 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_card_frame39.png: t_card_flash_f.png add_starfield.exe
	./add_starfield.exe $< 39 | convert -size 350x155 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_blank_icon.png: t_title_char_0.svg svg_to_png.sh
	./svg_to_png.sh $< $@ 903 40 967 104 48

t_striped_icon.png: t_blank_icon.png horizontal_stripes.exe
	./horizontal_stripes.exe < $< > $@

t_icon.png: t_blank_icon.png
	convert -size 32x32 xc:'#ffffff' -depth 8 -colorspace Gray $< -composite $@

t_icon_frame00.png: t_blank_icon.png add_dense_starfield.exe
	./add_dense_starfield.exe $< 0 | convert -size 32x32 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_icon_frame01.png: t_blank_icon.png add_dense_starfield.exe
	./add_dense_starfield.exe $< 1 | convert -size 32x32 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_icon_frame02.png: t_blank_icon.png add_dense_starfield.exe
	./add_dense_starfield.exe $< 2 | convert -size 32x32 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_icon_frame03.png: t_blank_icon.png add_dense_starfield.exe
	./add_dense_starfield.exe $< 3 | convert -size 32x32 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_icon_frame04.png: t_blank_icon.png add_dense_starfield.exe
	./add_dense_starfield.exe $< 4 | convert -size 32x32 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_icon_frame05.png: t_blank_icon.png add_dense_starfield.exe
	./add_dense_starfield.exe $< 5 | convert -size 32x32 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_icon_frame06.png: t_blank_icon.png add_dense_starfield.exe
	./add_dense_starfield.exe $< 6 | convert -size 32x32 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_icon_frame07.png: t_blank_icon.png add_dense_starfield.exe
	./add_dense_starfield.exe $< 7 | convert -size 32x32 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_icon_frame08.png: t_blank_icon.png add_dense_starfield.exe
	./add_dense_starfield.exe $< 8 | convert -size 32x32 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_icon_frame09.png: t_blank_icon.png add_dense_starfield.exe
	./add_dense_starfield.exe $< 9 | convert -size 32x32 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_icon_frame10.png: t_blank_icon.png add_dense_starfield.exe
	./add_dense_starfield.exe $< 10 | convert -size 32x32 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_icon_frame11.png: t_blank_icon.png add_dense_starfield.exe
	./add_dense_starfield.exe $< 11 | convert -size 32x32 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_icon_frame12.png: t_blank_icon.png add_dense_starfield.exe
	./add_dense_starfield.exe $< 12 | convert -size 32x32 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_icon_frame13.png: t_blank_icon.png add_dense_starfield.exe
	./add_dense_starfield.exe $< 13 | convert -size 32x32 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_icon_frame14.png: t_blank_icon.png add_dense_starfield.exe
	./add_dense_starfield.exe $< 14 | convert -size 32x32 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_icon_frame15.png: t_blank_icon.png add_dense_starfield.exe
	./add_dense_starfield.exe $< 15 | convert -size 32x32 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_icon_frame16.png: t_blank_icon.png add_dense_starfield.exe
	./add_dense_starfield.exe $< 16 | convert -size 32x32 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_icon_frame17.png: t_blank_icon.png add_dense_starfield.exe
	./add_dense_starfield.exe $< 17 | convert -size 32x32 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_icon_frame18.png: t_blank_icon.png add_dense_starfield.exe
	./add_dense_starfield.exe $< 18 | convert -size 32x32 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_icon_frame19.png: t_blank_icon.png add_dense_starfield.exe
	./add_dense_starfield.exe $< 19 | convert -size 32x32 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_icon_frame20.png: t_blank_icon.png add_dense_starfield.exe
	./add_dense_starfield.exe $< 20 | convert -size 32x32 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_icon_frame21.png: t_blank_icon.png add_dense_starfield.exe
	./add_dense_starfield.exe $< 21 | convert -size 32x32 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_icon_frame22.png: t_blank_icon.png add_dense_starfield.exe
	./add_dense_starfield.exe $< 22 | convert -size 32x32 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_icon_frame23.png: t_blank_icon.png add_dense_starfield.exe
	./add_dense_starfield.exe $< 23 | convert -size 32x32 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_icon_frame24.png: t_blank_icon.png add_dense_starfield.exe
	./add_dense_starfield.exe $< 24 | convert -size 32x32 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_icon_frame25.png: t_blank_icon.png add_dense_starfield.exe
	./add_dense_starfield.exe $< 25 | convert -size 32x32 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_icon_frame26.png: t_blank_icon.png add_dense_starfield.exe
	./add_dense_starfield.exe $< 26 | convert -size 32x32 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_icon_frame27.png: t_blank_icon.png add_dense_starfield.exe
	./add_dense_starfield.exe $< 27 | convert -size 32x32 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_icon_frame28.png: t_blank_icon.png add_dense_starfield.exe
	./add_dense_starfield.exe $< 28 | convert -size 32x32 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_icon_frame29.png: t_blank_icon.png add_dense_starfield.exe
	./add_dense_starfield.exe $< 29 | convert -size 32x32 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_icon_frame30.png: t_blank_icon.png add_dense_starfield.exe
	./add_dense_starfield.exe $< 30 | convert -size 32x32 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_icon_frame31.png: t_striped_icon.png add_dense_starfield.exe
	./add_dense_starfield.exe $< 31 | convert -size 32x32 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_icon_frame32.png: t_blank_icon.png add_dense_starfield.exe
	./add_dense_starfield.exe $< 32 | convert -size 32x32 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_icon_frame33.png: t_striped_icon.png add_dense_starfield.exe
	./add_dense_starfield.exe $< 33 | convert -size 32x32 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_icon_frame34.png: t_blank_icon.png add_dense_starfield.exe
	./add_dense_starfield.exe $< 34 | convert -size 32x32 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_icon_frame35.png: t_striped_icon.png add_dense_starfield.exe
	./add_dense_starfield.exe $< 35 | convert -size 32x32 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_icon_frame36.png: t_blank_icon.png add_dense_starfield.exe
	./add_dense_starfield.exe $< 36 | convert -size 32x32 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_icon_frame37.png: t_striped_icon.png add_dense_starfield.exe
	./add_dense_starfield.exe $< 37 | convert -size 32x32 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_icon_frame38.png: t_blank_icon.png add_dense_starfield.exe
	./add_dense_starfield.exe $< 38 | convert -size 32x32 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_icon_frame39.png: t_striped_icon.png add_dense_starfield.exe
	./add_dense_starfield.exe $< 39 | convert -size 32x32 xc:'#ffffff' -depth 8 -colorspace Gray png:- -composite $@

t_copyright.svg: world.svg select_layers.pl remove_unused_defs.pl
	perl select_layers.pl '^title copyright' t_copyright.png $< | perl remove_unused_defs.pl > $@

t_copyright.png: t_copyright.svg svg_to_png.sh
	./svg_to_png.sh $< $@ 996 216 1168 238

t_launch.png: t_title_all_chars.png t_copyright.png
	convert -size 400x240 xc:'#ffffff' -depth 8 -colorspace Gray '(' t_title_all_chars.png -geometry +103+78 ')' -composite '(' t_copyright.png -geometry +228+216 ')' -composite $@

# }}}

# ......................................................................
# {{{ Intermediate files.

# These are written to the current directory like everything else, but
# they mostly follow the naming convention of having a "t_" prefix, so
# it's easy to tell which files are transient.

t_large_digits.png: t_world.png crop_table.exe
	convert $< +repage -crop 512x192+0+0 png:- | ./crop_table.exe 32 96 20 32 6 0 > $@

t_small_digits.png: t_world.png crop_table.exe
	convert $< +repage -crop 152x64+0+544 png:- | ./crop_table.exe 8 32 8 13 0 0 > $@

t_dots.png: t_world.png
	convert $< +repage -crop 442x12+0+192 $@

t_sprites.png: t_world.png crop_table.exe
	convert $< +repage -crop 2048x960+0+640 png:- | ./crop_table 128 96 96 64 16 16 > $@

t_stars.png: generate_stars.exe
	./$< $@

t_world.png: t_world_gray.png fs_dither.exe
	./fs_dither.exe $< $@

t_world_gray.png: t_world.svg svg_to_png.sh
	./svg_to_png.sh $< $@

t_world.svg: world.svg select_layers.pl remove_unused_defs.pl add_rectangles.pl
	perl select_layers.pl '^world.*' t_world.png $< | perl remove_unused_defs.pl | perl add_rectangles.pl - > $@

t_title_background.png: t_world.png
	convert $< -crop 400x240+768+0 $@

t_title_char_table.png: \
	t_title_char_0.png \
	t_title_char_1.png \
	t_title_char_2.png \
	t_title_char_3.png \
	t_title_char_4.png \
	t_title_char_5.png \
	t_title_char_6.png \
	t_title_char_7.png \
	t_title_char_8.png \
	t_title_char_9.png \
	t_title_char_a.png \
	t_title_char_b.png \
	t_title_char_c.png \
	t_title_char_d.png \
	t_title_char_e.png \
	t_title_char_f.png \
	dither.exe
	convert -append t_title_char_0.png t_title_char_1.png t_title_char_2.png t_title_char_3.png t_title_char_4.png t_title_char_5.png t_title_char_6.png t_title_char_7.png t_title_char_8.png t_title_char_9.png t_title_char_a.png t_title_char_b.png t_title_char_c.png t_title_char_d.png t_title_char_e.png t_title_char_f.png png:- | ./dither.exe - - > $@

t_title_char_0.png: t_title_char_0.svg svg_to_png.sh
	./svg_to_png.sh $< $@ $(title_text_x1) $(title_text_y1) $(title_text_x2) $(title_text_y2)

t_title_char_1.png: t_title_char_1.svg svg_to_png.sh
	./svg_to_png.sh $< $@ $(title_text_x1) $(title_text_y1) $(title_text_x2) $(title_text_y2)

t_title_char_2.png: t_title_char_2.svg svg_to_png.sh
	./svg_to_png.sh $< $@ $(title_text_x1) $(title_text_y1) $(title_text_x2) $(title_text_y2)

t_title_char_3.png: t_title_char_3.svg svg_to_png.sh
	./svg_to_png.sh $< $@ $(title_text_x1) $(title_text_y1) $(title_text_x2) $(title_text_y2)

t_title_char_4.png: t_title_char_4.svg svg_to_png.sh
	./svg_to_png.sh $< $@ $(title_text_x1) $(title_text_y1) $(title_text_x2) $(title_text_y2)

t_title_char_5.png: t_title_char_5.svg svg_to_png.sh
	./svg_to_png.sh $< $@ $(title_text_x1) $(title_text_y1) $(title_text_x2) $(title_text_y2)

t_title_char_6.png: t_title_char_6.svg svg_to_png.sh
	./svg_to_png.sh $< $@ $(title_text_x1) $(title_text_y1) $(title_text_x2) $(title_text_y2)

t_title_char_7.png: t_title_char_7.svg svg_to_png.sh
	./svg_to_png.sh $< $@ $(title_text_x1) $(title_text_y1) $(title_text_x2) $(title_text_y2)

t_title_char_8.png: t_title_char_8.svg svg_to_png.sh
	./svg_to_png.sh $< $@ $(title_text_x1) $(title_text_y1) $(title_text_x2) $(title_text_y2)

t_title_char_9.png: t_title_char_9.svg svg_to_png.sh
	./svg_to_png.sh $< $@ $(title_text_x1) $(title_text_y1) $(title_text_x2) $(title_text_y2)

t_title_char_a.png: t_title_char_a.svg svg_to_png.sh
	./svg_to_png.sh $< $@ $(title_text_x1) $(title_text_y1) $(title_text_x2) $(title_text_y2)

t_title_char_b.png: t_title_char_b.svg svg_to_png.sh
	./svg_to_png.sh $< $@ $(title_text_x1) $(title_text_y1) $(title_text_x2) $(title_text_y2)

t_title_char_c.png: t_title_char_c.svg svg_to_png.sh
	./svg_to_png.sh $< $@ $(title_text_x1) $(title_text_y1) $(title_text_x2) $(title_text_y2)

t_title_char_d.png: t_title_char_d.svg svg_to_png.sh
	./svg_to_png.sh $< $@ $(title_text_x1) $(title_text_y1) $(title_text_x2) $(title_text_y2)

t_title_char_e.png: t_title_char_e.svg svg_to_png.sh
	./svg_to_png.sh $< $@ $(title_text_x1) $(title_text_y1) $(title_text_x2) $(title_text_y2)

t_title_char_f.png: t_title_char_f.svg svg_to_png.sh
	./svg_to_png.sh $< $@ $(title_text_x1) $(title_text_y1) $(title_text_x2) $(title_text_y2)

t_title_char_0.svg: world.svg select_layers.pl select_obj.pl remove_unused_defs.pl
	perl select_layers.pl '^title text' t_title.png $< | perl select_obj.pl 'title text' 'char_0' | perl remove_unused_defs.pl > $@

t_title_char_1.svg: world.svg select_layers.pl select_obj.pl remove_unused_defs.pl
	perl select_layers.pl '^title text' t_title.png $< | perl select_obj.pl 'title text' 'char_1' | perl remove_unused_defs.pl > $@

t_title_char_2.svg: world.svg select_layers.pl select_obj.pl remove_unused_defs.pl
	perl select_layers.pl '^title text' t_title.png $< | perl select_obj.pl 'title text' 'char_2' | perl remove_unused_defs.pl > $@

t_title_char_3.svg: world.svg select_layers.pl select_obj.pl remove_unused_defs.pl
	perl select_layers.pl '^title text' t_title.png $< | perl select_obj.pl 'title text' 'char_3' | perl remove_unused_defs.pl > $@

t_title_char_4.svg: world.svg select_layers.pl select_obj.pl remove_unused_defs.pl
	perl select_layers.pl '^title text' t_title.png $< | perl select_obj.pl 'title text' 'char_4' | perl remove_unused_defs.pl > $@

t_title_char_5.svg: world.svg select_layers.pl select_obj.pl remove_unused_defs.pl
	perl select_layers.pl '^title text' t_title.png $< | perl select_obj.pl 'title text' 'char_5' | perl remove_unused_defs.pl > $@

t_title_char_6.svg: world.svg select_layers.pl select_obj.pl remove_unused_defs.pl
	perl select_layers.pl '^title text' t_title.png $< | perl select_obj.pl 'title text' 'char_6' | perl remove_unused_defs.pl > $@

t_title_char_7.svg: world.svg select_layers.pl select_obj.pl remove_unused_defs.pl
	perl select_layers.pl '^title text' t_title.png $< | perl select_obj.pl 'title text' 'char_7' | perl remove_unused_defs.pl > $@

t_title_char_8.svg: world.svg select_layers.pl select_obj.pl remove_unused_defs.pl
	perl select_layers.pl '^title text' t_title.png $< | perl select_obj.pl 'title text' 'char_8' | perl remove_unused_defs.pl > $@

t_title_char_9.svg: world.svg select_layers.pl select_obj.pl remove_unused_defs.pl
	perl select_layers.pl '^title text' t_title.png $< | perl select_obj.pl 'title text' 'char_9' | perl remove_unused_defs.pl > $@

t_title_char_a.svg: world.svg select_layers.pl select_obj.pl remove_unused_defs.pl
	perl select_layers.pl '^title text' t_title.png $< | perl select_obj.pl 'title text' 'char_a' | perl remove_unused_defs.pl > $@

t_title_char_b.svg: world.svg select_layers.pl select_obj.pl remove_unused_defs.pl
	perl select_layers.pl '^title text' t_title.png $< | perl select_obj.pl 'title text' 'char_b' | perl remove_unused_defs.pl > $@

t_title_char_c.svg: world.svg select_layers.pl select_obj.pl remove_unused_defs.pl
	perl select_layers.pl '^title text' t_title.png $< | perl select_obj.pl 'title text' 'char_c' | perl remove_unused_defs.pl > $@

t_title_char_d.svg: world.svg select_layers.pl select_obj.pl remove_unused_defs.pl
	perl select_layers.pl '^title text' t_title.png $< | perl select_obj.pl 'title text' 'char_d' | perl remove_unused_defs.pl > $@

t_title_char_e.svg: world.svg select_layers.pl select_obj.pl remove_unused_defs.pl
	perl select_layers.pl '^title text' t_title.png $< | perl select_obj.pl 'title text' 'char_e' | perl remove_unused_defs.pl > $@

t_title_char_f.svg: world.svg select_layers.pl select_obj.pl remove_unused_defs.pl
	perl select_layers.pl '^title text' t_title.png $< | perl select_obj.pl 'title text' 'char_f' | perl remove_unused_defs.pl > $@

t_modes_table.png: t_world.png crop_table.exe
	convert $< -crop 128x48+512+0 png:- | ./crop_table.exe 64 48 61 44 2 3 > $@

# A choice of two songs are available at compile time, the default here is
# "Seiza ni Naretara" (seiza_ni_naretara.txt).  There is no run time option
# to select a different song, and honestly whatever song we use will not be
# so recognizable anyways because the chords will be played at random
# intervals due to varying chain lengths.
#
# That said, the other song we used during testing is Pachebel's Canon
# (canon.txt), and the chord progression in that is readily recognizable.
# The reason why it's recognizable is because it's Canon, and it's short.
# It will start sound to repetitive faster than "Seiza ni Naretara".
t_note_groups.lua: seiza_ni_naretara.txt get_max_note_channels.pl
	cp $< $@
	perl get_max_note_channels.pl $< >> $@

t_rates.lua: generate_rate_table.pl
	perl $< > $@

t_cursor_poly.lua: generate_cursor_poly.pl
	perl $< > $@

t_drift_offsets.lua: generate_drift_offsets.pl
	perl $< > $@

t_permutations6.lua: generate_permutations6.rb
	ruby $< > $@

t_bit_table.lua: generate_bit_table.pl
	perl $< > $@

t_itch_cover.png: t_itch_cover.svg t_aa_svg_to_png.sh
	bash t_aa_svg_to_png.sh $< $@ 1280 0 1910 500

t_itch_cover.svg: world.svg select_layers.pl remove_unused_defs.pl
	perl select_layers.pl '^itch cover' t_itch_cover.png $< | perl remove_unused_defs.pl > $@

# SVG rasterizer script with anti-aliasing enabled (i.e. without the flag
# to disable anti-aliasing).
t_aa_svg_to_png.sh: svg_to_png.sh
	grep -vF "export-png-antialias=0" $< > $@

# }}}

# ......................................................................
# {{{ Tools.

assemble_tiles.exe: assemble_tiles.c
	gcc $(cflags) $< -lpng -o $@

dither.exe: dither.c
	gcc $(cflags) $< -lpng -o $@

fs_dither.exe: fs_dither.c
	gcc $(cflags) $< -lpng -o $@

random_dither.exe: random_dither.c
	gcc $(cflags) $< -lpng -o $@

crop_table.exe: crop_table.c
	gcc $(cflags) $< -lpng -o $@

shrink_tiles.exe: shrink_tiles.c
	gcc $(cflags) $< -lpng -o $@

stack_bw.exe: stack_bw.c
	gcc $(cflags) $< -lpng -o $@

horizontal_stripes.exe: horizontal_stripes.c
	gcc $(cflags) $< -lpng -o $@

add_starfield.exe: add_starfield.c
	gcc $(cflags) $< -lpng -o $@

add_dense_starfield.exe: add_starfield.c
	gcc $(cflags) -DRADIUS=3 $< -lpng -o $@

generate_stars.exe: generate_stars.c
	gcc $(cflags) $< -lpng -o $@

# }}}

# ......................................................................
# {{{ Debug images.

# These are used to render various images for faster image iteration.
# The expected workflow is:
# 1. Make an edit in Inkscape.
# 2. Run "make" for the updated target to dump the image into console
#    as upscaled sixel data.
#
# We need this because the source image data is vector-based SVGs, but the
# game uses rasterized pixel data that might need repeated adjustments to
# get all the pixels into the right place.  Running "make" and reloading the
# updated bitmap in some image editing tool is too slow because it requires
# an additional roundtrip through another app.  But with a sixel-capable
# terminal, we can just run "make" and get the updated image immediately.

debug_z0: t_sprites.png
	convert -size 96x64 xc:'#0000ff' -depth 8 '(' $< -crop 96x64+192+0 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_z1: t_sprites.png
	convert -size 96x64 xc:'#0000ff' -depth 8 '(' $< -crop 96x64+288+0 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_z2: t_sprites.png
	convert -size 96x64 xc:'#0000ff' -depth 8 '(' $< -crop 96x64+384+0 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_z3: t_sprites.png
	convert -size 96x64 xc:'#0000ff' -depth 8 '(' $< -crop 96x64+480+0 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_z4: t_sprites.png
	convert -size 96x64 xc:'#0000ff' -depth 8 '(' $< -crop 96x64+576+0 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_z5: t_sprites.png
	convert -size 96x64 xc:'#0000ff' -depth 8 '(' $< -crop 96x64+672+0 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_z6: t_sprites.png
	convert -size 96x64 xc:'#0000ff' -depth 8 '(' $< -crop 96x64+768+0 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_z7: t_sprites.png
	convert -size 96x64 xc:'#0000ff' -depth 8 '(' $< -crop 96x64+864+0 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_z8: t_sprites.png
	convert -size 96x64 xc:'#0000ff' -depth 8 '(' $< -crop 96x64+960+0 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_z9: t_sprites.png
	convert -size 96x64 xc:'#0000ff' -depth 8 '(' $< -crop 96x64+1056+0 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_z10: t_sprites.png
	convert -size 96x64 xc:'#0000ff' -depth 8 '(' $< -crop 96x64+1152+0 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_z11: t_sprites.png
	convert -size 96x64 xc:'#0000ff' -depth 8 '(' $< -crop 96x64+1248+0 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_z12: t_sprites.png
	convert -size 96x64 xc:'#0000ff' -depth 8 '(' $< -crop 96x64+1344+0 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_z13: t_sprites.png
	convert -size 96x64 xc:'#0000ff' -depth 8 '(' $< -crop 96x64+1440+0 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_z14: t_sprites.png
	convert -size 96x64 xc:'#0000ff' -depth 8 '(' $< -crop 96x64+0+64 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_z15: t_sprites.png
	convert -size 96x64 xc:'#0000ff' -depth 8 '(' $< -crop 96x64+96+64 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_z16: t_sprites.png
	convert -size 96x64 xc:'#0000ff' -depth 8 '(' $< -crop 96x64+192+64 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_z17: t_sprites.png
	convert -size 96x64 xc:'#0000ff' -depth 8 '(' $< -crop 96x64+288+64 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_z18: t_sprites.png
	convert -size 96x64 xc:'#0000ff' -depth 8 '(' $< -crop 96x64+384+64 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_z19: t_sprites.png
	convert -size 96x64 xc:'#0000ff' -depth 8 '(' $< -crop 96x64+480+64 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_z20: t_sprites.png
	convert -size 96x64 xc:'#0000ff' -depth 8 '(' $< -crop 96x64+576+64 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_z21: t_sprites.png
	convert -size 96x64 xc:'#0000ff' -depth 8 '(' $< -crop 96x64+672+64 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_z22: t_sprites.png
	convert -size 96x64 xc:'#0000ff' -depth 8 '(' $< -crop 96x64+768+64 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_z23: t_sprites.png
	convert -size 96x64 xc:'#0000ff' -depth 8 '(' $< -crop 96x64+864+64 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_z24: t_sprites.png
	convert -size 96x64 xc:'#0000ff' -depth 8 '(' $< -crop 96x64+960+64 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_z25: t_sprites.png
	convert -size 96x64 xc:'#0000ff' -depth 8 '(' $< -crop 96x64+1056+64 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_z26: t_sprites.png
	convert -size 96x64 xc:'#0000ff' -depth 8 '(' $< -crop 96x64+1152+64 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_z27: t_sprites.png
	convert -size 96x64 xc:'#0000ff' -depth 8 '(' $< -crop 96x64+1248+64 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_z28: t_sprites.png
	convert -size 96x64 xc:'#0000ff' -depth 8 '(' $< -crop 96x64+1344+64 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_z29: t_sprites.png
	convert -size 96x64 xc:'#0000ff' -depth 8 '(' $< -crop 96x64+1440+64 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_bz0: t_sprites.png
	convert -size 96x64 xc:'#000000' -depth 8 '(' $< -crop 96x64+192+0 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_bz1: t_sprites.png
	convert -size 96x64 xc:'#000000' -depth 8 '(' $< -crop 96x64+288+0 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_bz2: t_sprites.png
	convert -size 96x64 xc:'#000000' -depth 8 '(' $< -crop 96x64+384+0 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_bz3: t_sprites.png
	convert -size 96x64 xc:'#000000' -depth 8 '(' $< -crop 96x64+480+0 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_bz4: t_sprites.png
	convert -size 96x64 xc:'#000000' -depth 8 '(' $< -crop 96x64+576+0 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_bz5: t_sprites.png
	convert -size 96x64 xc:'#000000' -depth 8 '(' $< -crop 96x64+672+0 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_bz6: t_sprites.png
	convert -size 96x64 xc:'#000000' -depth 8 '(' $< -crop 96x64+768+0 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_bz7: t_sprites.png
	convert -size 96x64 xc:'#000000' -depth 8 '(' $< -crop 96x64+864+0 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_bz8: t_sprites.png
	convert -size 96x64 xc:'#000000' -depth 8 '(' $< -crop 96x64+960+0 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_bz9: t_sprites.png
	convert -size 96x64 xc:'#000000' -depth 8 '(' $< -crop 96x64+1056+0 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_bz10: t_sprites.png
	convert -size 96x64 xc:'#000000' -depth 8 '(' $< -crop 96x64+1152+0 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_bz11: t_sprites.png
	convert -size 96x64 xc:'#000000' -depth 8 '(' $< -crop 96x64+1248+0 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_bz12: t_sprites.png
	convert -size 96x64 xc:'#000000' -depth 8 '(' $< -crop 96x64+1344+0 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_bz13: t_sprites.png
	convert -size 96x64 xc:'#000000' -depth 8 '(' $< -crop 96x64+1440+0 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_bz14: t_sprites.png
	convert -size 96x64 xc:'#000000' -depth 8 '(' $< -crop 96x64+0+64 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_bz15: t_sprites.png
	convert -size 96x64 xc:'#000000' -depth 8 '(' $< -crop 96x64+96+64 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_bz16: t_sprites.png
	convert -size 96x64 xc:'#000000' -depth 8 '(' $< -crop 96x64+192+64 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_bz17: t_sprites.png
	convert -size 96x64 xc:'#000000' -depth 8 '(' $< -crop 96x64+288+64 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_bz18: t_sprites.png
	convert -size 96x64 xc:'#000000' -depth 8 '(' $< -crop 96x64+384+64 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_bz19: t_sprites.png
	convert -size 96x64 xc:'#000000' -depth 8 '(' $< -crop 96x64+480+64 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_bz20: t_sprites.png
	convert -size 96x64 xc:'#000000' -depth 8 '(' $< -crop 96x64+576+64 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_bz21: t_sprites.png
	convert -size 96x64 xc:'#000000' -depth 8 '(' $< -crop 96x64+672+64 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_bz22: t_sprites.png
	convert -size 96x64 xc:'#000000' -depth 8 '(' $< -crop 96x64+768+64 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_bz23: t_sprites.png
	convert -size 96x64 xc:'#000000' -depth 8 '(' $< -crop 96x64+864+64 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_bz24: t_sprites.png
	convert -size 96x64 xc:'#000000' -depth 8 '(' $< -crop 96x64+960+64 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_bz25: t_sprites.png
	convert -size 96x64 xc:'#000000' -depth 8 '(' $< -crop 96x64+1056+64 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_bz26: t_sprites.png
	convert -size 96x64 xc:'#000000' -depth 8 '(' $< -crop 96x64+1152+64 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_bz27: t_sprites.png
	convert -size 96x64 xc:'#000000' -depth 8 '(' $< -crop 96x64+1248+64 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_bz28: t_sprites.png
	convert -size 96x64 xc:'#000000' -depth 8 '(' $< -crop 96x64+1344+64 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_bz29: t_sprites.png
	convert -size 96x64 xc:'#000000' -depth 8 '(' $< -crop 96x64+1440+64 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_dialog: t_world.png
	convert -size 128x50 xc:'#0000ff' -depth 8 '(' $< -crop 128x50+512+0 -geometry +0+0 ')' -composite -scale '300%%' six:-

debug_title: t_world.png
	convert -size 400x240 xc:'#0000ff' -depth 8 '(' $< -crop 400x240+768+0 -geometry +0+0 ')' -composite -scale '200%%' six:-

debug_copyright: t_copyright.png
	convert -size 172x20 xc:'#ffffff' -depth 8 $< -composite -scale '300%%' six:-

debug_launch: t_launch.png
	convert $< -scale '200%%' six:-

debug_blank_icon: t_blank_icon.png
	convert -size 32x32 xc:'#0000ff' -depth 8 $< -composite -scale '300%%' six:-

debug_card: t_card.gif
	ls -l $<

t_card.gif: \
	t_card_frame00.png \
	t_card_frame01.png \
	t_card_frame02.png \
	t_card_frame03.png \
	t_card_frame04.png \
	t_card_frame05.png \
	t_card_frame06.png \
	t_card_frame07.png \
	t_card_frame08.png \
	t_card_frame09.png \
	t_card_frame10.png \
	t_card_frame11.png \
	t_card_frame12.png \
	t_card_frame13.png \
	t_card_frame14.png \
	t_card_frame15.png \
	t_card_frame16.png \
	t_card_frame17.png \
	t_card_frame18.png \
	t_card_frame19.png \
	t_card_frame20.png \
	t_card_frame21.png \
	t_card_frame22.png \
	t_card_frame23.png \
	t_card_frame24.png \
	t_card_frame25.png \
	t_card_frame26.png \
	t_card_frame27.png \
	t_card_frame28.png \
	t_card_frame29.png \
	t_card_frame30.png \
	t_card_frame31.png \
	t_card_frame32.png \
	t_card_frame33.png \
	t_card_frame34.png \
	t_card_frame35.png \
	t_card_frame36.png \
	t_card_frame37.png \
	t_card_frame38.png \
	t_card_frame39.png
	ffmpeg -framerate 20 -i 't_card_frame%02d.png' -y $@

debug_icon: t_icon.gif
	ls -l $<

t_icon.gif: \
	t_icon_frame00.png \
	t_icon_frame01.png \
	t_icon_frame02.png \
	t_icon_frame03.png \
	t_icon_frame04.png \
	t_icon_frame05.png \
	t_icon_frame06.png \
	t_icon_frame07.png \
	t_icon_frame08.png \
	t_icon_frame09.png \
	t_icon_frame10.png \
	t_icon_frame11.png \
	t_icon_frame12.png \
	t_icon_frame13.png \
	t_icon_frame14.png \
	t_icon_frame15.png \
	t_icon_frame16.png \
	t_icon_frame17.png \
	t_icon_frame18.png \
	t_icon_frame19.png \
	t_icon_frame20.png \
	t_icon_frame21.png \
	t_icon_frame22.png \
	t_icon_frame23.png \
	t_icon_frame24.png \
	t_icon_frame25.png \
	t_icon_frame26.png \
	t_icon_frame27.png \
	t_icon_frame28.png \
	t_icon_frame29.png \
	t_icon_frame30.png \
	t_icon_frame31.png \
	t_icon_frame32.png \
	t_icon_frame33.png \
	t_icon_frame34.png \
	t_icon_frame35.png \
	t_icon_frame36.png \
	t_icon_frame37.png \
	t_icon_frame38.png \
	t_icon_frame39.png
	ffmpeg -framerate 20 -i 't_icon_frame%02d.png' -y $@

# }}}

# ......................................................................
# {{{ Tests and maintenance commands.

test: \
	test_passed.brighten \
	test_passed.check_ref \
	test_passed.cleanup_styles \
	test_passed.crop_table \
	test_passed.dither \
	test_passed.element_count \
	test_passed.generate_build_graph \
	test_passed.inline_constants \
	test_passed.no_text \
	test_passed.select_layers \
	test_passed.shrink_tiles \
	test_passed.stack_bw \
	test_passed.strip_lua

test_passed.dither: dither.exe test_dither.sh
	./test_dither.sh $< && touch $@

test_passed.remove_unused_defs: remove_unused_defs.pl test_remove_unused_defs.sh
	./test_remove_unused_defs.sh $< && touch $@

test_passed.select_layers: select_layers.pl test_select_layers.sh
	./test_select_layers.sh $< && touch $@

test_passed.generate_build_graph: generate_build_graph.pl test_generate_build_graph.sh
	./test_generate_build_graph.sh $< && touch $@

test_passed.strip_lua: strip_lua.pl test_strip_lua.sh
	./test_strip_lua.sh $< && touch $@

test_passed.check_ref: check_ref.pl test_check_ref.sh
	./test_check_ref.sh $< && touch $@

test_passed.inline_constants: inline_constants.pl test_inline_constants.sh
	./test_inline_constants.sh $< && touch $@

test_passed.element_count: element_count.pl test_element_count.sh
	./test_element_count.sh $< && touch $@

test_passed.cleanup_styles: cleanup_styles.pl test_cleanup_styles.sh
	./test_cleanup_styles.sh $< && touch $@

test_passed.brighten: brighten.pl test_brighten.sh
	./test_brighten.sh $< && touch $@

test_passed.crop_table: crop_table.exe test_crop_table.sh
	./test_crop_table.sh $< && touch $@

test_passed.shrink_tiles: shrink_tiles.exe test_shrink_tiles.sh
	./test_shrink_tiles.sh $< && touch $@

test_passed.stack_bw: stack_bw.exe test_stack_bw.sh
	./test_stack_bw.sh $< && touch $@

test_passed.no_text: t_world.svg element_count.pl
	! ( perl element_count.pl $< | grep '^text' ) && touch $@


clean:
	-rm -f $(targets) *.exe *.o test_passed.* t_*

# }}}
