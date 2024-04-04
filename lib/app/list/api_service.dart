// Customize
const int kPreloadLimit = 10;

// Customize
const int kNextLimit = 30;

// For better UX, latency should be minimum.
// For demo: 2s is taken but something under a second will be better
const int kLatency = 2;

// 사용법
//  final List<String> _urls = await ApiService.getVideos();
class ApiService {
  static final List<String> _videos = [
    'https://res.cloudinary.com/dfbxar2j5/video/upload/v1712062655/VID_2024-04-02_09-55-271119998743_lqtn3c.mp4',
    'https://res.cloudinary.com/dfbxar2j5/video/upload/v1712062918/VID_2024-04-02_10-01-17-277601888_yhlf7f.mp4',
    'https://res.cloudinary.com/dfbxar2j5/video/upload/v1712063169/VID_2024-04-02_10-05-381928330495_sgfgpc.mp4',
    'https://res.cloudinary.com/dfbxar2j5/video/upload/v1712063315/VID_2024-04-02_10-07-27-1247146133_zpqyek.mp4',
    'https://res.cloudinary.com/dfbxar2j5/video/upload/v1712063492/VID_2024-04-02_10-10-59320796923_ueg38w.mp4',
    'https://res.cloudinary.com/dfbxar2j5/video/upload/v1712063901/VID_2024-04-02_10-17-341518806275_yzksuk.mp4',
    'https://res.cloudinary.com/dfbxar2j5/video/upload/v1712064450/VID_2024-04-02_10-26-11-811574925_fysjhk.mp4',
    'https://res.cloudinary.com/dfbxar2j5/video/upload/v1712064617/VID_2024-04-02_10-29-57-853825574_jdj7wv.mp4',
    'https://res.cloudinary.com/dfbxar2j5/video/upload/v1712064756/VID_2024-04-02_10-31-38-665660466_i9tpqe.mp4',
    'https://res.cloudinary.com/dfbxar2j5/video/upload/v1712065307/VID_2024-04-02_10-41-08-562090897_we9opg.mp4',
    'https://assets.mixkit.co/videos/preview/mixkit-woman-turning-off-her-alarm-clock-42897-large.mp4',
    'https://assets.mixkit.co/videos/preview/mixkit-pair-of-plantain-stalks-in-a-close-up-shot-42956-large.mp4',
    'https://assets.mixkit.co/videos/preview/mixkit-aerial-view-of-city-traffic-at-night-11-large.mp4',
    'https://assets.mixkit.co/videos/preview/mixkit-countryside-meadow-4075-large.mp4',
    'https://assets.mixkit.co/videos/preview/mixkit-texture-of-different-fruits-42959-large.mp4',
    'https://assets.mixkit.co/videos/preview/mixkit-landscape-of-mountains-and-sunset-3128-large.mp4',
    'https://assets.mixkit.co/videos/preview/mixkit-woman-washing-her-hair-while-taking-a-bath-42915-large.mp4',
    'https://assets.mixkit.co/videos/preview/mixkit-clouds-and-blue-sky-2408-large.mp4',
    'https://assets.mixkit.co/videos/preview/mixkit-different-types-of-fresh-fruit-in-presentation-video-42941-large.mp4',
    'https://assets.mixkit.co/videos/preview/mixkit-forest-stream-in-the-sunlight-529-large.mp4',
    'https://assets.mixkit.co/videos/preview/mixkit-stunning-sunset-seen-from-the-sea-4119-large.mp4',
    'https://assets.mixkit.co/videos/preview/mixkit-meadow-surrounded-by-trees-on-a-sunny-afternoon-40647-large.mp4',
    'https://assets.mixkit.co/videos/preview/mixkit-fruit-texture-in-a-humid-environment-42958-large.mp4',
    'https://assets.mixkit.co/videos/preview/mixkit-close-up-shot-of-a-turntable-playing-a-record-42920-large.mp4',
    'https://assets.mixkit.co/videos/preview/mixkit-woman-serving-eggs-in-a-pan-for-breakfast-42909-large.mp4',
    'https://assets.mixkit.co/videos/preview/mixkit-close-view-of-a-record-rotating-on-a-turntable-42921-large.mp4',
    'https://assets.mixkit.co/videos/preview/mixkit-young-woman-finishing-preparing-her-breakfast-42911-large.mp4',
    'https://assets.mixkit.co/videos/preview/mixkit-waterfall-in-forest-2213-large.mp4',
    'https://assets.mixkit.co/videos/preview/mixkit-close-up-view-of-a-rotating-vinyl-record-42922-large.mp4',
    'https://assets.mixkit.co/videos/preview/mixkit-going-down-a-curved-highway-down-a-mountain-41576-large.mp4',
    'https://assets.mixkit.co/videos/preview/mixkit-lake-surrounded-by-dry-grass-in-the-savanna-5030-large.mp4',
    'https://assets.mixkit.co/videos/preview/mixkit-aerial-panorama-of-a-landscape-with-mountains-and-a-lake-4249-large.mp4',
    'https://assets.mixkit.co/videos/preview/mixkit-curvy-road-on-a-tree-covered-hill-41537-large.mp4',
    'https://assets.mixkit.co/videos/preview/mixkit-frying-diced-bacon-in-a-skillet-43063-large.mp4',
    'https://assets.mixkit.co/videos/preview/mixkit-young-woman-taking-a-shower-42916-large.mp4',
    'https://assets.mixkit.co/videos/preview/mixkit-rain-falling-on-the-water-of-a-lake-seen-up-18312-large.mp4',
    'https://assets.mixkit.co/videos/preview/mixkit-people-pouring-a-warm-drink-around-a-campfire-513-large.mp4',
    'https://assets.mixkit.co/videos/preview/mixkit-stars-in-space-1610-large.mp4',
    'https://assets.mixkit.co/videos/preview/mixkit-fireworks-illuminating-the-beach-sky-4157-large.mp4',
    'https://assets.mixkit.co/videos/preview/mixkit-huge-trees-in-a-large-green-forest-5040-large.mp4',
    'https://assets.mixkit.co/videos/preview/mixkit-close-up-shot-of-a-computers-internal-system-42924-large.mp4',
    'https://assets.mixkit.co/videos/preview/mixkit-lots-of-chips-and-dice-arranged-on-a-game-table-42931-large.mp4',
    'https://assets.mixkit.co/videos/preview/mixkit-fresh-apples-in-a-row-on-a-natural-background-42946-large.mp4',
    'https://assets.mixkit.co/videos/preview/mixkit-very-close-shot-of-the-leaves-of-a-tree-wet-18310-large.mp4',
    'https://assets.mixkit.co/videos/preview/mixkit-woman-preparing-her-lunch-in-the-morning-42908-large.mp4',
    'https://assets.mixkit.co/videos/preview/mixkit-woman-flipping-her-egg-omelet-42910-large.mp4',
    'https://assets.mixkit.co/videos/preview/mixkit-top-aerial-shot-of-seashore-with-rocks-1090-large.mp4',
    'https://assets.mixkit.co/videos/preview/mixkit-close-tour-through-the-middle-of-an-open-book-42926-large.mp4',
    'https://assets.mixkit.co/videos/preview/mixkit-white-sand-beach-and-palm-trees-1564-large.mp4',
    'https://assets.mixkit.co/videos/preview/mixkit-young-woman-waking-up-in-the-morning-42896-large.mp4'
  ];

  /// Simulate api call
  static Future<List<String>> getVideos({int id = 0}) async {
    // No more videos
    if ((id >= _videos.length)) {
      return [];
    }

    await Future.delayed(const Duration(seconds: kLatency));

    if ((id + kNextLimit >= _videos.length)) {
      return _videos.sublist(id, _videos.length);
    }

    return _videos.sublist(id, id + kNextLimit);
  }
}
