import pyperclip

# define metatiles
meta1 = "$00,$01,$10,$11"
meta2 = "$02,$03,$12,$13"
meta3 = "$06,$07,$16,$17"
backg = "$00,$00,$00,$00"

# define mappings
metatile_map = {}
metatile_map[meta1] = "00"
metatile_map[meta2] = "01"
metatile_map[meta3] = "10"
metatile_map[backg] = "11"

# screen path and background label
SCREEN_PATH = "nexxt/coin_collector_background.asm"
BG_LABEL    = "coin_collector_background"

# define screen width and length
WIDTH  = 32
HEIGHT = 30

def load_screen(path, label_name):
    contents = ""
    with open(path, 'r', encoding='utf-8') as file:
        contents = file.read()
    
    # remove ".byte" directive and label name
    contents = contents.replace(".byte", ",").replace(f"{label_name}:", "")

    # Remove spaces, newlines, and tabs
    contents = contents.replace(" ", "").replace("\n", "").replace("\t", "")

    # remove space between characters
    contents = contents.strip()

    # remove first comma
    contents = contents.replace(",", "", 1)

    # return contents as a list of hex valies
    return contents.split(",")

def compress(contents, height, width):
    compressed = ""
    compressed_list = []

    it = 0
    row_a = []
    row_b = []
    for i in range(height):
        for j in range(width):
            if it % 2 == 0:
                row_a.append(contents[i*width + j])
            else:
                row_b.append(contents[i*width + j])
        it += 1

        if it % 2 == 0:
            # check if 4x4 tile spot is a valid metatile
            for i, n in enumerate(range(0, len(row_a), 2)):
                metatile = ""
                metatile += row_a[n] + ","
                metatile += row_a[n+1] + ","
                metatile += row_b[n] + ","
                metatile += row_b[n+1]
                
                if metatile in metatile_map:
                    compressed += metatile_map[metatile]
                else:
                    compressed += "11"

                if (i + 1) % 4 == 0:
                    compressed_list.append(compressed)
                    compressed = ""
            
            row_a = []
            row_b = []
    
    # append remaining data (i.e., the attribute table)
    compressed_list.extend(contents[width*height:])

    return compressed_list

def format(compressed, uncompressed, height, width):
    formatted = "hud:\n\t.byte "
    formatted += ",".join(uncompressed)

    formatted += "\n\nbackground:\n\t.byte "
    for i, n in enumerate(compressed[:int((width/8)*(height/2))]):
        formatted += f"%{n}, "
        if (i+1) % 4 == 0:
            formatted = formatted.rstrip(", ")
            formatted += "\n\t.byte "
    
    formatted = formatted.rstrip("\t.byte ")
    formatted += "\nattributes:\n\t.byte "
    for i, n in enumerate(compressed[int((width/8)*(height/2)):]):
        formatted += f"{n},"
        if (i+1) % 16 == 0:
            formatted = formatted.rstrip(", ")
            formatted += "\n\t.byte "
    
    formatted = formatted.rstrip(".byte ")
    return formatted

def main():
    # `contents` is a list of hex values representing every background tile.
    contents = load_screen(SCREEN_PATH, BG_LABEL)
    
    # Skip the first 64 values in `contents`, since these won't be compressed.
    uncompressed = contents[:64]
    compressed = compress(contents[64:], HEIGHT - 2, WIDTH)
    
    # format output
    formatted = format(compressed, uncompressed, HEIGHT - 2, WIDTH)
    
    pyperclip.copy(formatted)
    print("Compressed background copied to clipboard.")

if __name__ == "__main__":
    main()
