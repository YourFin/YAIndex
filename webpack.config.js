const path = require('path');
const HtmlWebpackPlugin = require('html-webpack-plugin');
const { CleanWebpackPlugin } = require('clean-webpack-plugin');

module.exports = env => {
  let prod = env.prod;
  // Force the user to spell out whether this is a production run or not
  if (prod !== "false" && prod !== "true") {
    console.log('Error: Production node environment variable set')
    process.exit(1);
  }
  prod = env.prod === "true";
  console.log(
    `
Running in ${prod ? "production" : "development"} mode.
`
  );
  return {
    mode: prod ? 'production' : 'development',
    devtool: prod ? '' /* none */ : 'cheap-module-eval-source-map',
    devServer: prod ? {} : {
      contentBase: './dist',
      hot: true,
      historyApiFallback: true, // Allows serving webapp at all paths
      //disableHostCheck: true,
    },
    entry: './src/index.js',
    plugins: [
      new CleanWebpackPlugin(), // Clean up dist directory
      new HtmlWebpackPlugin({
        template: '!!handlebars-loader!src/index.html.hbs',
        title: 'Output Management',
      }),
    ],
    module: {
      rules: [ // How to handle different filetypes
        { // handlebars templates
          test: /\.(handlebars|hbs)$/i,
          use: [
            'handlebars-loader',
          ]
        },
        { // elm
          test: /\.elm$/i,
          exclude: [/elm-stuff/, /node_modules/],
          use: [ { loader: 'elm-hot-webpack-loader' },
                 {
                   loader: 'elm-webpack-loader',
                   options: {
                     cwd: __dirname, // directory with elm.json,
                                     // which contains actual file locations
                     maxInstances: 4,
                     optimize: prod,
                     verbose: !prod,
                     debug: !prod,
                   },
                 },
               ],
        },
        { // sass
          test: /\.(scss|sass)$/i,
          use: [
            // Creates `style` nodes from JS strings
            'style-loader',
            // Translates CSS into CommonJS
            'css-loader',
            // Compiles Sass to CSS
            'sass-loader',
          ]
        },
        { // svg
          test: /\.svg$/i,
          loader: 'svg-inline-loader',
        },
        { // fonts
          test: /\.(woff|woff2|eot|ttf|otf)$/,
          use: [
            'file-loader'
          ]
        },
        { // images
          test: /\.(png|jpg|jpeg|gif)$/i,
          use: [
            'file-loader',
          ]
        }
      ],
    },
    output: {
      filename: prod ? '[name].[hash].js' : '[name].js',
      path: path.resolve(__dirname, 'dist'),
    },
  }
};
