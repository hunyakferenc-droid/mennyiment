"""Serve the unpacked MennyiMent checkpoint locally; Python 3, no packages."""
import argparse
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import threading
import webbrowser


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--directory', type=Path, default=Path(__file__).resolve().parent / 'web')
    parser.add_argument('--port', type=int, default=7357)
    parser.add_argument('--no-browser', action='store_true')
    args = parser.parse_args()
    if not (args.directory / 'index.html').is_file():
        parser.error('Nem található a web/index.html. Előbb bontsd ki a teljes ZIP-et.')
    handler = partial(SimpleHTTPRequestHandler, directory=str(args.directory.resolve()))
    handler.func.extensions_map.update({'.wasm': 'application/wasm', '.js': 'text/javascript'})
    url = f'http://127.0.0.1:{args.port}'
    try:
        server = ThreadingHTTPServer(('127.0.0.1', args.port), handler)
    except OSError as error:
        parser.error(f'A helyi kiszolgáló nem indult: {error}. Másik port: --port 7358')
    print(f'MennyiMent? – {url}\nNyisd meg Chrome-ban. Leállítás: Ctrl+C.', flush=True)
    if not args.no_browser:
        threading.Timer(.5, lambda: webbrowser.open(url)).start()
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == '__main__':
    main()
