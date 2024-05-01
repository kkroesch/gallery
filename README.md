# Gallery

Justfile and some Python code to create static galleries from folders of images.

## Installation

Needs Python, [Just](https://github.com/casey/just) and Imagemagick. For local preview, Nginx must be installed as well.  

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

just -l
```
