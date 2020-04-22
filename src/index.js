// Application entrypoint

import {Elm} from '../elm-src/Main.elm';
import './components/elm-video';
import './packs/global-styles';

document.addEventListener('DOMContentLoaded', () => {
  Elm.Main.init({flags:
                 { 'server-index': '/raw/'
                   , 'webapp-root': '/c/' }});
});
