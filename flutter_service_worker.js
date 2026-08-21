'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {".git/COMMIT_EDITMSG": "2eaace7939c4cc098d9bca8d75f91cb7",
".git/config": "39447217fa0a97a6382b6cac139a15c8",
".git/description": "a0a7c3fff21f2aea3cfa1d0316dd816c",
".git/HEAD": "5ab7a4355e4c959b0c5c008f202f51ec",
".git/hooks/applypatch-msg.sample": "ce562e08d8098926a3862fc6e7905199",
".git/hooks/commit-msg.sample": "e0b5b08e209fa15f48d796e8976bc42b",
".git/hooks/fsmonitor-watchman.sample": "5c90c1740b0cacecb469934e16fe8cb6",
".git/hooks/post-update.sample": "2b7ea5cee3c49ff53d41e00785eb974c",
".git/hooks/pre-applypatch.sample": "054f9ffb8bfe04a599751cc757226dda",
".git/hooks/pre-commit.sample": "5029bfab85b1c39281aa9697379ea444",
".git/hooks/pre-merge-commit.sample": "39cb268e2a85d436b9eb6f47614c3cbc",
".git/hooks/pre-push.sample": "2c642152299a94e05ea26eae11993b13",
".git/hooks/pre-rebase.sample": "56e45f2bcbc8226d2b4200f7c46371bf",
".git/hooks/pre-receive.sample": "2ad18ec82c20af7b5926ed9cea6aeedd",
".git/hooks/prepare-commit-msg.sample": "2b5c047bdb474555e1787db32b2d2fc5",
".git/hooks/push-to-checkout.sample": "c7ab00c7784efeadad3ae9b228d4b4db",
".git/hooks/sendemail-validate.sample": "4d67df3a8d5c98cb8565c07e42be0b04",
".git/hooks/update.sample": "647ae13c682f7827c22f5fc08a03674e",
".git/index": "99fd2d5cbfa13ad8b5a7b500de2df7dc",
".git/info/exclude": "036208b4a1ab4a235d75c181e685e5a3",
".git/logs/HEAD": "16734bd2ba11adf914bd1e4d48830a73",
".git/logs/refs/heads/gh-pages": "bdfa17509b642784779c441f12ca7cab",
".git/logs/refs/remotes/origin/gh-pages": "0c99dfb51cd56215f3d2dcaac890ed81",
".git/objects/00/d5dae47a138a3781180ab9b9fdd4576232781d": "10cc9f53944d8e1444b6d16a9b77751d",
".git/objects/03/8e1c37cc34f7511a48b786c0236239e5b0943d": "97373c2dc5d8279b0be9e2ceee3fc051",
".git/objects/08/32d0db2def1613c1c45aa4fe9156a1c6b7d589": "e05df183e5eeaddf39672a2516f9c41d",
".git/objects/10/2066d2c81740a27e5105d9d69e3b1bcef36763": "84433c4bdba95142b6969aee913337fc",
".git/objects/10/ace35b0ad877fe86a7b5c9a18f720119d3a1eb": "86d55286137a587a43783580d9930c5b",
".git/objects/10/d02a56fccccbf86206da53352b978e0ed3a0cf": "e002b574a5e1f16ce0a9cdd0db26ce9a",
".git/objects/14/ff49a131c36e14d3ae93b71b50f9248bd50fcf": "5f4cf90f2c6c63598f0ed3b150d7f247",
".git/objects/1c/16ec1fa86f4f8d1ef3542fe281fa6511f684cc": "c1b3b0b870bf7b82cdbd2179ab9c7cc5",
".git/objects/1d/466446a0cf54287529d08f6040af339c2962b9": "60660aa7bea4d35923970e519e663fbd",
".git/objects/26/fd8f615984e099ccefc82bbdd8f36c2779b5b9": "94a6edaeffe1320cdf7e8a0887b6cb48",
".git/objects/28/4bd47863ab0541b52ffc3b750db067e42575dc": "9dc322b24d6a3f32bb2770fc65b63ec7",
".git/objects/31/1e3132867223d5f90afe1a76def660fb1fcd65": "88a4d01e68d58cde9683954de8f9cac3",
".git/objects/32/aa3cae58a7432051fc105cc91fca4d95d1d011": "4f8558ca16d04c4f28116d3292ae263d",
".git/objects/33/066b94cadd00e8118c79e4657f5292e84ed92a": "6f5d081b7d90eb8fdcaf230a6d828ae1",
".git/objects/37/fa4e7dfa0d4db59c6a8702256a6c8283895751": "0665aad3a20af13228c08c0db397f9d2",
".git/objects/3a/50bcf246953eac45889af16d2b3677deda2eba": "8088ab04e577ee09b6b83d07fe7586ee",
".git/objects/3a/7525f2996a1138fe67d2a0904bf5d214bfd22c": "ab6f2f6356cba61e57d5c10c2e18739d",
".git/objects/3f/66a65b2ba68fb66b4f6e20f1d2da2633601adb": "d968f603342adb859bfac0bc46e85d70",
".git/objects/40/0d5b186c9951e294699e64671b9dde52c6f6a0": "f6bd3c7f9b239e8898bace6f9a7446b9",
".git/objects/40/594f8caad5a8d4eaad83c2e0593300ba57b5b7": "c463bfd4c15260129005596d48049d02",
".git/objects/44/a8b8e41b111fcf913a963e318b98e7f6976886": "5014fdb68f6b941b7c134a717a3a2bc6",
".git/objects/4c/ab3f50a457076148678be3fd4b561c7d59fa45": "62b63c2c36f2d74f603a66a5281e0877",
".git/objects/50/305a44466b0df8a18e6b23346f7ad6f39fdd92": "f247db617516b2ca25e01b5ae9eca657",
".git/objects/50/c94bbbdead5e44d1c4420e9808f282822ce659": "99e1b8039c372fc2b843627ef4011396",
".git/objects/51/308ff6fb6cfcba2562ebeeeb01339c9d2acdb9": "f4cb0d8ea6bade1a28f3a8b153054489",
".git/objects/51/765fefff38443ce82729bb9c6ca6535fda5408": "84aa83d8407292ca28232be63d8bd4e7",
".git/objects/51/7903f01e2e9235cc6526f112b6b0f43c8950f7": "7e3c6a102183c7d322b059166d79d1f5",
".git/objects/55/305912a87c2b1034ab8f57d7befba1432c77c7": "cc115fa5dd38f1a7cf13bd6f5e6d21d0",
".git/objects/57/5003a6eccf2c70570cfe166bcc5b6fc32d268c": "ad2f227c59e813a2e325e030fd284555",
".git/objects/5e/b298ee81bc69567502cf1d91ecfaa2c1d0168e": "73cf6d0357e3b6fa0bba86b8e5f04264",
".git/objects/61/e8b4ab881711fd6dc7b0c2601b25034b22e6f8": "3999b566f64e4e6730d574460bd2f760",
".git/objects/67/c296d3205c5364ac4b98e8fe6217801a479ae7": "d434079b6401e3189edfbfc141b47872",
".git/objects/6b/e909fbf40b23748412f0ea89bf0fae827ed976": "5f118419157d9534688915220cc803f7",
".git/objects/73/855caa205d3832cd4f629e334b8a73ff0d0a8f": "3b98c478621c6974c473f8424abb0193",
".git/objects/75/f98b63e5160035b035b055a0016e4cdaf36055": "72eb10ce36075bb0a5ca7bb0fa9684f6",
".git/objects/77/074dd795e1c821896c8530dce03d65db2fa10f": "8106297db807f08f6aa567b7d0f7ba7f",
".git/objects/78/e03fd00b96eb84a54707097e72392c36b09802": "4ed4a93d15b79df9d9c31668e2f1f45c",
".git/objects/80/411d2281949de45dbd1c22a33602ab1bcd1eb1": "861cdacdf4a020a2c4e6cee8c3f434bd",
".git/objects/84/0516208d35dcb4298847ab835e2ef84ada92fa": "36a4a870d8d9c1c623d8e1be329049da",
".git/objects/87/70d9d3a083f65ed650c01bf699115086f1a65b": "4ae1030df17d19ca6b2c9ba2a8d5f5f2",
".git/objects/88/cfd48dff1169879ba46840804b412fe02fefd6": "e42aaae6a4cbfbc9f6326f1fa9e3380c",
".git/objects/8a/aa46ac1ae21512746f852a42ba87e4165dfdd1": "1d8820d345e38b30de033aa4b5a23e7b",
".git/objects/8d/016b06daf41f86bb46cb8ebed3688b57f65116": "caf66ba88d5f13866bf06fec979214ad",
".git/objects/90/0d46da47787c95012553341d2aa35875768799": "577b392f6e643f0be42303957c4c807d",
".git/objects/90/bcfcf0a77ab618a826db0fd8b0942963b653af": "fc109675cdf1233dd6599a4c3c0a7a69",
".git/objects/98/57c9b3b0448c92818efc5fda0f206b21914168": "ecbde07c564dabbec0f249821051b8af",
".git/objects/98/e1132dff5ee2e9f7199383ee36e83924c304aa": "9b8c858e9f564cb8b75153864df4bd99",
".git/objects/9d/3f496c0651da53c4f40eb6e34259ae426c2bcb": "d1344231fe90b9175028c0e5dc86a140",
".git/objects/a3/0da92700d764412411097d92281b5338d7baa6": "98957d9f1e5689890a7fe586919591ee",
".git/objects/a6/04735e0dda9b8a0a0b2d4f4d7dacfb79e65103": "01350d79aff6216258b99ebd350f56d0",
".git/objects/ac/7afd3139716bf526d2b55e4591ae1547cfee67": "9f655e92d51cc7023c854dbe65c6fb28",
".git/objects/b1/5ad935a6a00c2433c7fadad53602c1d0324365": "8f96f41fe1f2721c9e97d75caa004410",
".git/objects/b1/ee4181ba8cd03878ccce21b936c63965c656ba": "46094be8d34260b76b2d2b7ccbf7d885",
".git/objects/b7/49bfef07473333cf1dd31e9eed89862a5d52aa": "36b4020dca303986cad10924774fb5dc",
".git/objects/b9/2a0d854da9a8f73216c4a0ef07a0f0a44e4373": "f62d1eb7f51165e2a6d2ef1921f976f3",
".git/objects/bd/dfecb735030c1f902c049fa90a5911be1f26f0": "d2d87e5dad9ec9e3795e3bb5127ca030",
".git/objects/c6/e518d634f28b0b796f7b696653c0d6bd4ebc34": "b39a50b7cfb99e9fc1968ef1d6c4d6a5",
".git/objects/c8/f6d1603c838c252c51b272145d5e3f30abf9c3": "63bf9be3d9c7f753e9452cdd8b9ca4e1",
".git/objects/d0/23371979cf1e985205df19078051c10de0a82d": "700b71074bad7afee32068791dec7442",
".git/objects/d1/2a29d04022bf344a86d15ea162e631f3787d18": "067f23a09eadffaf12a5aa0285522003",
".git/objects/d3/73f0ed0879b0ab67041b0b4f263eb8e5cddd03": "9d8a98e2dc7a18cc9fce8c0b035e7be8",
".git/objects/d4/3532a2348cc9c26053ddb5802f0e5d4b8abc05": "3dad9b209346b1723bb2cc68e7e42a44",
".git/objects/d5/bb50b3c3bc534b51ba035a5e8495ba7af5025b": "81d30e6f235d2cd1960b1a0d917b3043",
".git/objects/d6/9c56691fbdb0b7efa65097c7cc1edac12a6d3e": "868ce37a3a78b0606713733248a2f579",
".git/objects/d7/053a83dc2a814993308814f8c2d95e15b9b46c": "3035add57f17c5910bf2af6eb54b1703",
".git/objects/d7/7221889cea2ae5bab876f3717574f74327da17": "c7c3f954e788853eb34813247f156683",
".git/objects/da/fd65422747502c19b5c74b4230282644d2169c": "d8a62caf99a372ff6c7692e143787ce3",
".git/objects/e8/b073ae01aaaed67c72714f499aedad71752e14": "26510ce095fca633db3859aedefc33bf",
".git/objects/eb/9b4d76e525556d5d89141648c724331630325d": "37c0954235cbe27c4d93e74fe9a578ef",
".git/objects/ef/4f721738a84e67863a916ab2ef77cf51688401": "d4a6054baf06e385cebd0fe04653ce90",
".git/objects/f0/b09a243992b3be8ae01525e3e1b79e08c098e6": "286d339f547ee55b62d286e291d0de5f",
".git/objects/f1/b8633e9e44d2f8fc865bf713a467ef56b90c04": "16819a318099108bfa57473cba6d274f",
".git/objects/f2/04823a42f2d890f945f70d88b8e2d921c6ae26": "6b47f314ffc35cf6a1ced3208ecc857d",
".git/objects/f9/1a8ead16232c8c4631202c98ffec20c3d1ac49": "84f2529b7812397504e0eb7ea7a18a19",
".git/objects/fb/4966ebcaffbbee02cc4a2e33ee19dd85a344ba": "e344a399f2ad4fcad66da507ddc09f2f",
".git/objects/fe/578e096dbd4cb10136a5b0447c0f819bc2017b": "083f1e42bca60c8a7e14e878f9686ca2",
".git/objects/ff/cc5476d1fcbfbb429f827f9aaf52efe73b3822": "bf15e1570697e4e6af53741257331d16",
".git/refs/heads/gh-pages": "4bdf28011815293476fa1009bcbacb37",
".git/refs/remotes/origin/gh-pages": "07f93ba71cc415330c5542cf3cf7b08f",
"assets/AssetManifest.bin": "cb873045425e589d5e29a3c0af817218",
"assets/AssetManifest.bin.json": "73a24fe65ef547661958f4fad4ae68a9",
"assets/AssetManifest.json": "043919e04b0466b4fec620b8d33c1e12",
"assets/assets/fonts/EkusheyBelycon.ttf": "8e65ab8b226f093737dfc5110989dab5",
"assets/assets/fonts/Jameel%2520Noori%2520Nastaleeq%2520Regular.ttf": "4b37da11a19bd60a9432a7603aada419",
"assets/assets/fonts/JameelNooriNastaleeqKasheeda.ttf": "0feabd6c9714cc4bb922bfb16e1ef20f",
"assets/assets/fonts/KFGQPC%2520Uthmanic%2520Script%2520HAFS%2520Regular.otf": "43269f118299246de0cf264e04ae2680",
"assets/assets/fonts/mylotus%2520Regular.ttf": "38a80057509f6251f5d9f8a822e5715e",
"assets/assets/fonts/SolaimanLipi_22-02-2012.ttf": "7e1fcf28519e63325caa3c163bb315d3",
"assets/assets/fonts/Traditional%2520Naskh%2520Regular.ttf": "ede4d5e5ac18d65706673f8037812f25",
"assets/assets/images/app_icon.png": "6036f490bb2d88cdff118ee71aa26ca8",
"assets/assets/images/logo.png": "87c7a46f56c883ab8bc234e7ff436d09",
"assets/FontManifest.json": "39f9f93a2f60b52b42ea49f7666ffe36",
"assets/fonts/MaterialIcons-Regular.otf": "3b222ec3c72f64a62344fdf46de3e606",
"assets/NOTICES": "d3f76765f6a1a35b6ec3f35b0bbf538d",
"assets/packages/hugeicons/lib/fonts/hugeicons-stroke-rounded.ttf": "ed1746fbad500fea94f6e5c5eb97ed7d",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "66177750aff65a66cb07bb44b8c6422b",
"canvaskit/canvaskit.js.symbols": "48c83a2ce573d9692e8d970e288d75f7",
"canvaskit/canvaskit.wasm": "1f237a213d7370cf95f443d896176460",
"canvaskit/chromium/canvaskit.js": "671c6b4f8fcc199dcc551c7bb125f239",
"canvaskit/chromium/canvaskit.js.symbols": "a012ed99ccba193cf96bb2643003f6fc",
"canvaskit/chromium/canvaskit.wasm": "b1ac05b29c127d86df4bcfbf50dd902a",
"canvaskit/skwasm.js": "694fda5704053957c2594de355805228",
"canvaskit/skwasm.js.symbols": "262f4827a1317abb59d71d6c587a93e2",
"canvaskit/skwasm.wasm": "9f0c0c02b82a910d12ce0543ec130e60",
"canvaskit/skwasm.worker.js": "89990e8c92bcb123999aa81f7e203b1c",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "f393d3c16b631f36852323de8e583132",
"flutter_bootstrap.js": "4219a0c7ed0776f065e4292ac3b27d66",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "569681079e9187dbadbf06503ee63d2c",
"/": "569681079e9187dbadbf06503ee63d2c",
"main.dart.js": "dfcd1bf4ebbbfd2deb662df4a22ce52c",
"manifest.json": "a0f68f1a1ef6f634be99ba66e20df00a",
"sqflite_sw.js": "50b88460590c9bbe52c00155f142631d",
"sqlite3.wasm": "2068781fd3a05f89e76131a98da09b5b",
"version.json": "a9d96586f0a7dd8c769fab7dff839346"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
