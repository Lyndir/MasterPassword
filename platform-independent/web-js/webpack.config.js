const webpack = require('webpack');
const path = require('path');

module.exports = {
  entry: ["babel-polyfill", './src/main.js'],
  output: {
    filename: 'bundle.js',
    path: path.resolve(__dirname, 'dist')
  },
  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /node_modules/,
        loader: "babel-loader"
      },
    ]
  },
  plugins: [
    new webpack.ProvidePlugin({
      $: "jquery",
      jQuery: "jquery"
    })
  ],
  devServer: {
    contentBase: path.join(__dirname, "dist"),
    port: 8080
  },
  mode: 'development'
};
