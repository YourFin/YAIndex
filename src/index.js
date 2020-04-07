//import _ from 'lodash';
//
//function component() {
//const element = document.createElement('div');
//
//element.innerHTML = _.join(['Hello', 'webpack'], ' ');
//
//return element;
//}
//
//document.body.appendChild(component());

import {Elm} from '../elm-src/Main.elm';
import './components/elm-video';
import './packs/global-styles';

document.addEventListener('DOMContentLoaded', () => {
  Elm.Main.init({flags:
                 { 'server-index': '/raw/'
                   , 'webapp-root': '/c/'}});
});
