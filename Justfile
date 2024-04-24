serve:
    #!/bin/bash
    NGINX=$(which nginx)
    ${NGINX} -g 'daemon off;' -p $PWD -c config/nginx.conf

thumbs:
    #!/bin/bash
    thumb_size=250
    find ./public -maxdepth 1 -type d | while read -r dir; do
        cd "$dir"
        echo "in $PWD"
        mkdir -p "thumbs"
        find . -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) | while read -r img; do
            # Ermitteln der Dimensionen
            dimensions=$(identify -format "%wx%h" "$img")
            width=$(cut -d'x' -f1 <<< "$dimensions")
            height=$(cut -d'x' -f2 <<< "$dimensions")

            # Berechnen der kleinsten Dimension
            size=$width
            if [ $height -lt $width ]; then
                size=$height
            fi

            echo -n "."
            # Erstellen eines quadratischen Thumbnails
            convert "$img" \
                -thumbnail "${size}x${size}^" \
                -gravity center -extent "${size}x${size}" \
                -resize "${thumb_size}x${thumb_size}" \
                "thumbs/$img"
        done
        echo ""
        cd ${OLDPWD}
    done
    # Cleanup empty dirs
    find . -type d -empty -exec rmdir {} +

clean:
    find . -name index.html -exec rm {} \;


    
catalog:
    #!/usr/bin/env python
    from jinja2 import Environment, FileSystemLoader
    import os

    def generate_directory_list(dir):
        file_loader = FileSystemLoader('.')
        env = Environment(loader=file_loader)
        template = env.get_template('template/catalog.html')

        folders = []

        # Überprüfen von Unterverzeichnissen und suchen nach cover.jpg
        for entry in os.listdir(dir):
            full_path = os.path.join(dir, entry)
            if os.path.isdir(full_path):
                cover_image = os.path.join(full_path, 'cover.jpeg')
                if os.path.exists(cover_image):
                    folder_title = entry.capitalize()
                    folders.append({
                        'href': os.path.join('/', entry, 'index.html'),
                        'thumb': os.path.join('/', entry, 'thumbs', 'cover.jpeg'),
                        'title': folder_title
                    })

        if folders:
            rendered_html = template.render(folders=folders)
            html_path = os.path.join(dir, 'index.html')
            with open(html_path, 'w') as file:
                file.write(rendered_html)
            print(f'Die Verzeichnisliste wurde erfolgreich in {dir} erstellt!')

    # Durchlaufen aller Unterverzeichnisse unter 'public'
    public_root = os.path.join('.', 'public')
    generate_directory_list(public_root)


index:
    #!/usr/bin/env python
    from jinja2 import Environment, FileSystemLoader
    import os

    def generate_html(dir):
        # Jinja2 Environment Setup
        file_loader = FileSystemLoader('.')
        env = Environment(loader=file_loader)
        template = env.get_template('template/gallery.html')
        
        # Bilder und Thumbnails sammeln
        thumb_dir = os.path.join(dir, 'thumbs')
        images = []
        if os.path.exists(thumb_dir):
            for img in sorted(os.listdir(thumb_dir)):
                if img.endswith(('.jpg', '.jpeg', '.png', '.gif')):
                    images.append({
                        'href': os.path.join('/', os.path.relpath(dir, 'public'), img), 
                        'src': os.path.join('/', os.path.relpath(dir, 'public'), 'thumbs', img),
                        'title': img
                    })

        # HTML mit Jinja2 generieren
        rendered_html = template.render(images=images)

        # HTML in index.html schreiben
        with open(os.path.join(dir, 'index.html'), 'w') as file:
            file.write(rendered_html)

        print(f'Die HTML-Seite wurde erfolgreich in {dir} erstellt!')

    public_root = os.path.join('.', 'public')
    for root, dirs, files in os.walk(public_root):
        if 'thumbs' in dirs:
            dirs.remove('thumbs') 
        generate_html(root)
