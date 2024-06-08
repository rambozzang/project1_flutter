String uviValueToString(double uvi) {
  if (uvi <= 2) {
    return '낮음';
  } else if (uvi <= 5) {
    return '중간';
  } else if (uvi <= 7) {
    return '높음';
  } else if (uvi <= 10) {
    return '아주높음';
  } else if (uvi >= 11) {
    return '최고높음';
  }
  return 'Unknown';
}

String getWeatherImage(String input) {
  String weather = input.toLowerCase();
  String assetPath = 'assets/lottie/';
  // String assetPath = 'assets/images/';
  switch (weather) {
    case 'thunderstorm':
      return assetPath + 'Storm.json';

    case 'drizzle':
    case 'rain':
      return assetPath + 'day_rain.json';

    case 'snow':
      return assetPath + 'day_snow.json';

    case 'clear':
      return assetPath + 'sun.json';

    case 'clouds':
      return assetPath + 'day_cloudy.json';

    case 'mist':
    case 'fog':
    case 'smoke':
    case 'haze':
    case 'dust':
    case 'sand':
    case 'ash':
      return assetPath + 'day_cloudy.json';

    case 'squall':
    case 'tornado':
      return assetPath + 'wind.json';

    default:
      return assetPath + 'day_cloudy.json';
  }
}

//


// String getWeatherImage(String input) {
//   String weather = input.toLowerCase();
//   String assetPath = 'assets/lottie/';
//   // String assetPath = 'assets/images/';
//   switch (weather) {
//     case 'thunderstorm':
//       return assetPath + 'Storm.json';

//     case 'drizzle':
//     case 'rain':
//       return assetPath + 'Rainy.png';

//     case 'snow':
//       return assetPath + 'Snow.png';

//     case 'clear':
//       return assetPath + 'Sunny.png';

//     case 'clouds':
//       return assetPath + 'Cloudy.png';

//     case 'mist':
//     case 'fog':
//     case 'smoke':
//     case 'haze':
//     case 'dust':
//     case 'sand':
//     case 'ash':
//       return assetPath + 'Fog.png';

//     case 'squall':
//     case 'tornado':
//       return assetPath + 'StormWindy.png';

//     default:
//       return assetPath + 'Cloud.png';
//   }
// }
