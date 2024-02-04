// import 'dart:convert';
// import 'dart:io';

// import 'package:path/path.dart' as p;

// ///
// class MenuJsonFileItem {
//   ///
//   MenuJsonFileItem({
//     required this.id,
//     required this.parentId,
//     required this.title,
//     required this.path,
//     required this.weight,
//     required this.hasItems,
//   });

//   ///
//   factory MenuJsonFileItem.empty() {
//     return MenuJsonFileItem(id: -1, parentId: -1, title: '', path: '', weight: 0, hasItems: false);
//   }

//   ///
//   final int id;

//   ///
//   final int parentId;

//   ///
//   final String title;

//   ///
//   final String path;

//   ///
//   final int weight;

//   ///
//   final bool hasItems;
// }

// ///
// class HtmlMenuToJson {
//   ///
//   Future<List<MenuJsonFileItem>> getAllItemsFromMenuJsonFile(
//     Website websited,
//   ) async {
//     final items = <MenuJsonFileItem>[];

//     const basePath = AppConfig.localRepositoryPath;
//     final path = p.join(basePath, '.temp', 'en', website.contentDirectoryName, 'menu.json');

//     final json = List<Map<dynamic, dynamic>>.from(
//       jsonDecode(await File(path).readAsString()) as Iterable,
//     );

//     var idCount = 1;

//     // Add the root item.
//     items.add(
//       MenuJsonFileItem(
//         id: idCount,
//         parentId: -1,
//         title: website.title,
//         path: '',
//         weight: 1,
//         hasItems: true,
//       ),
//     );

//     void processJsonList(List<Map<dynamic, dynamic>> jsonList, int parentId) {
//       var weight = 1;
//       for (final jsonItem in jsonList) {
//         idCount++;
//         if (jsonItem['items'] != null) {
//           items.add(
//             MenuJsonFileItem(
//               id: idCount,
//               parentId: parentId,
//               title: jsonItem['title'] as String,
//               path: jsonItem['path'] as String,
//               weight: weight,
//               hasItems: true,
//             ),
//           );

//           processJsonList(List<Map<dynamic, dynamic>>.from(jsonItem['items'] as Iterable), idCount);
//         } else {
//           items.add(
//             MenuJsonFileItem(
//               id: idCount,
//               parentId: parentId,
//               title: jsonItem['title'] as String,
//               path: jsonItem['path'] as String,
//               weight: weight,
//               hasItems: false,
//             ),
//           );
//         }
//         weight++;
//       }
//     }

//     processJsonList(json, idCount);

//     return items;
//   }
// }
