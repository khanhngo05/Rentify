import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

/// Script giúp chèn nhanh link ảnh trực tiếp vào Firestore
/// Hướng dẫn:
/// 1. Thay link ảnh thật của bạn vào các map bên dưới.
/// 2. Code `await UpdateImages.execute();` trong main.dart.
/// 3. Chạy app 1 lần rồi xóa dòng gọi hàm đi.
class UpdateImages {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. CHÈN LINK ẢNH CHI NHÁNH VÀO ĐÂY
  static const Map<String, String> branchImageUrls = {
    'branch_001':
        'https://drive.google.com/file/d/1f-o81oNTsSGDKqO-sR1EOAj4HLsfQHkO/view?usp=sharing',
    'branch_002':
        'https://drive.google.com/file/d/1_ne0kVFA8RERg-uauTcRvKe0g6ZKCgpF/view?usp=sharing',
    'branch_003':
        'https://drive.google.com/file/d/1YkNb0qdfu9e9BPHS4yr81_ETI22WjSs_/view?usp=sharing',
  };

  // 2. CHÈN LINK ẢNH SẢN PHẨM VÀO ĐÂY (prod_001 đến prod_030)
  // [Link Thumbnail (ảnh đại diện nhỏ), Link ảnh full 1, Link ảnh full 2...]
  static const Map<String, List<String>> productImages = {
    'prod_001': [
      'https://bizweb.dktcdn.net/100/236/196/products/ao-dai-cuoi-56.jpg?v=1586857920463', // Ảnh Thumbnail (Cái đầu tiên)
      'https://bizweb.dktcdn.net/100/236/196/products/ao-dai-cuoi-56.jpg?v=1586857920463', // Cắc ảnh slide chi tiết
      'https://bizweb.dktcdn.net/100/236/196/products/ao-dai-cuoi-62.jpg?v=1586852321357',
    ],
    'prod_002': [
      'https://thekat.vn/wp-content/uploads/2024/03/DSC00762-scaled.jpg',
      'https://thekat.vn/wp-content/uploads/2024/03/DSC00762-scaled.jpg',
      'https://dkaodai.vn/wp-content/uploads/2020/04/NTT010.jpg',
    ],
    // Bạn có thể tiếp tục copy pase dưới đây (chỉ điền các product bạn muốn cập nhật)
    'prod_003': [
      'https://product.hstatic.net/200000821157/product/1_1f680b00ab9941ddb04ad1cc9454c109_master.jpg',
      'https://product.hstatic.net/200000821157/product/1_1f680b00ab9941ddb04ad1cc9454c109_master.jpg',
      'https://hhluxury.vn/storage/images/4WpwDajmVWGOZGNyEs0BILcqcVSEtN181yLFW2H3.jpg',
    ],
    'prod_004': [
      'https://namtuyen.com/upload/baiviet/ao-dai-nam-ao-dai-ngu-than-truyen-thong-nam-tuyen-6-3576.jpg',
      'https://namtuyen.com/upload/baiviet/ao-dai-nam-ao-dai-ngu-than-truyen-thong-nam-tuyen-6-3576.jpg',
    ],
    'prod_005': [
      'https://scontent.fhan3-2.fna.fbcdn.net/v/t39.30808-6/659651870_933730916072933_3781871976436552344_n.jpg?_nc_cat=100&ccb=1-7&_nc_sid=13d280&_nc_eui2=AeGBqQfpE_8yraHCTKK3aQwdnU4Ces5G2kOdTgJ6zkbaQ9TMHbGB8NNTtMs73INkjXzuclgJmJr0D-B8hjce8Uis&_nc_ohc=85g5IEiwf_sQ7kNvwE0pW2T&_nc_oc=AdqhHOAIlFEKyKuUBBd-2ySCfxv4AEQO4qKSVEiGU60U1XnIf7uO1pgLGeJsuckpGcpQZ-MtiGvAVjmh3zbUforR&_nc_zt=23&_nc_ht=scontent.fhan3-2.fna&_nc_gid=QyIKxPq_25JJduLAeO8cOQ&_nc_ss=7a3a8&oh=00_Afy_099rzPBLeYTkjEDNAYfa0ijgWZcBE_OajxjdJ2qXgA&oe=69D04A26',
      'https://scontent.fhan3-2.fna.fbcdn.net/v/t39.30808-6/659651870_933730916072933_3781871976436552344_n.jpg?_nc_cat=100&ccb=1-7&_nc_sid=13d280&_nc_eui2=AeGBqQfpE_8yraHCTKK3aQwdnU4Ces5G2kOdTgJ6zkbaQ9TMHbGB8NNTtMs73INkjXzuclgJmJr0D-B8hjce8Uis&_nc_ohc=85g5IEiwf_sQ7kNvwE0pW2T&_nc_oc=AdqhHOAIlFEKyKuUBBd-2ySCfxv4AEQO4qKSVEiGU60U1XnIf7uO1pgLGeJsuckpGcpQZ-MtiGvAVjmh3zbUforR&_nc_zt=23&_nc_ht=scontent.fhan3-2.fna&_nc_gid=QyIKxPq_25JJduLAeO8cOQ&_nc_ss=7a3a8&oh=00_Afy_099rzPBLeYTkjEDNAYfa0ijgWZcBE_OajxjdJ2qXgA&oe=69D04A26',
    ],
    'prod_006': [
      'https://bellabridal.vn/public/upload/files/486405546_671924138727643_186434444312228704_n.jpg',
      'https://bellabridal.vn/public/upload/files/486405546_671924138727643_186434444312228704_n.jpg',
    ],
    'prod_007': [
      'https://scontent.fhan3-1.fna.fbcdn.net/v/t39.30808-6/621846661_881662177946474_1663238808915402119_n.jpg?_nc_cat=102&ccb=1-7&_nc_sid=13d280&_nc_eui2=AeEfRMAFOiKGTukb_-bZu_241TevnYqzSCnVN6-dirNIKVrbySbgdcvxbGXBB_V6Ddxg_PNGf0LtYP_z5Y4uIc4K&_nc_ohc=HQWvNOnrqKUQ7kNvwG8_-qe&_nc_oc=AdqBeNLfSJiEYJvEjAXU8EImx9w2gAseou5Su2H2fiDb-zAoNGLj2sjAp5j3HS49A1CbdJ2_qC4JR--aKwxcZvDL&_nc_zt=23&_nc_ht=scontent.fhan3-1.fna&_nc_gid=MbLwKfMtyof8ulEnkATiAg&_nc_ss=7a3a8&oh=00_AfwsWpj3mfpFjGrG7HHLYHwXCdMt9Kb8CnJ3HzEWcTv6IA&oe=69D02A62',
      'https://scontent.fhan3-1.fna.fbcdn.net/v/t39.30808-6/621846661_881662177946474_1663238808915402119_n.jpg?_nc_cat=102&ccb=1-7&_nc_sid=13d280&_nc_eui2=AeEfRMAFOiKGTukb_-bZu_241TevnYqzSCnVN6-dirNIKVrbySbgdcvxbGXBB_V6Ddxg_PNGf0LtYP_z5Y4uIc4K&_nc_ohc=HQWvNOnrqKUQ7kNvwG8_-qe&_nc_oc=AdqBeNLfSJiEYJvEjAXU8EImx9w2gAseou5Su2H2fiDb-zAoNGLj2sjAp5j3HS49A1CbdJ2_qC4JR--aKwxcZvDL&_nc_zt=23&_nc_ht=scontent.fhan3-1.fna&_nc_gid=MbLwKfMtyof8ulEnkATiAg&_nc_ss=7a3a8&oh=00_AfwsWpj3mfpFjGrG7HHLYHwXCdMt9Kb8CnJ3HzEWcTv6IA&oe=69D02A62',
    ],
    'prod_008': [
      'https://alohastudio.vn/wp-content/uploads/2020/11/vay-cuoi-lech-vai-body.jpg',
      'https://alohastudio.vn/wp-content/uploads/2020/11/vay-cuoi-lech-vai-body.jpg',
    ],
    'prod_009': [
      'https://www.lunss.com/uploads/product/1/Y/1Y091/sparkly-gold-unique-geometric-pattern-sequin-prom-dress-1.webp',
      'https://www.lunss.com/uploads/product/1/Y/1Y091/sparkly-gold-unique-geometric-pattern-sequin-prom-dress-1.webp',
    ],
    'prod_010': [
      'https://bizweb.dktcdn.net/100/456/597/products/326bnew.jpg?v=1743302919730',
      'https://bizweb.dktcdn.net/100/456/597/products/326bnew.jpg?v=1743302919730',
    ],
    'prod_011': [
      'https://encrypted-tbn0.gstatic.com/shopping?q=tbn:ANd9GcSQ3Ml4Z_x8n4PsDaa6SZcbMKqsiO4UyJl-9d_nFbeWDkf1lXkg6CXRGp5XLirPTTaN6Gkpe7uTnMPwyak96_QWAxR-1-BPdmz91etSG5s6gL6_EYvkFijueXEm_8VITnZJgz7q9Q&usqp=CAc',
      'https://encrypted-tbn0.gstatic.com/shopping?q=tbn:ANd9GcSQ3Ml4Z_x8n4PsDaa6SZcbMKqsiO4UyJl-9d_nFbeWDkf1lXkg6CXRGp5XLirPTTaN6Gkpe7uTnMPwyak96_QWAxR-1-BPdmz91etSG5s6gL6_EYvkFijueXEm_8VITnZJgz7q9Q&usqp=CAc',
    ],
    'prod_012': [
      'https://darlingdiva.vn/cdn/shop/files/z7360034617277_ea61b779395067457de6c405e68fc9b2.jpg?v=1766733918&width=1200',
      'https://darlingdiva.vn/cdn/shop/files/z7360034617277_ea61b779395067457de6c405e68fc9b2.jpg?v=1766733918&width=1200',
    ],
    'prod_013': [
      'https://encrypted-tbn3.gstatic.com/shopping?q=tbn:ANd9GcSMMTWbZKLBoNj6VIk8vKpS_6xdoJmEUX2ACpXuzZGYkKxNKJDfvkJOljlh0ugpLo2k-UVn6NEytPgTn5tg9CQavLQY1Ctdi5AlgauYG0jk0Q6g_NtJIWCbRuNZvUN8YqRaR_cYMsXYtA&usqp=CAc',
      'https://encrypted-tbn3.gstatic.com/shopping?q=tbn:ANd9GcSMMTWbZKLBoNj6VIk8vKpS_6xdoJmEUX2ACpXuzZGYkKxNKJDfvkJOljlh0ugpLo2k-UVn6NEytPgTn5tg9CQavLQY1Ctdi5AlgauYG0jk0Q6g_NtJIWCbRuNZvUN8YqRaR_cYMsXYtA&usqp=CAc',
    ],
    'prod_014': [
      'https://bizweb.dktcdn.net/thumb/1024x1024/100/314/343/products/bo-09.jpg?v=1681114175753',
      'https://bizweb.dktcdn.net/thumb/1024x1024/100/314/343/products/bo-09.jpg?v=1681114175753',
    ],
    'prod_015': [
      'https://bizweb.dktcdn.net/thumb/1024x1024/100/314/343/products/b9-1.jpg?v=1691573213097',
      'https://bizweb.dktcdn.net/thumb/1024x1024/100/314/343/products/b9-1.jpg?v=1691573213097',
    ],
    'prod_016': [
      'https://encrypted-tbn3.gstatic.com/shopping?q=tbn:ANd9GcQKIffzFa9xoNvKH7T181JszVpbGxNRxJxgC3jlgL18mbHDGjI0VudBgzj39puPqZ98phXcX2aPrYDj8fyxihJ3xWZ_MYqeGuHF0Hg1DEjrCFXDC3WCg2YJoMm7k_6G6QRRwPVPtoO9bJ4&usqp=CAc',
      'https://encrypted-tbn3.gstatic.com/shopping?q=tbn:ANd9GcQKIffzFa9xoNvKH7T181JszVpbGxNRxJxgC3jlgL18mbHDGjI0VudBgzj39puPqZ98phXcX2aPrYDj8fyxihJ3xWZ_MYqeGuHF0Hg1DEjrCFXDC3WCg2YJoMm7k_6G6QRRwPVPtoO9bJ4&usqp=CAc',
    ],
    'prod_017': [
      'https://joteta.com/cdn/shop/files/Traditional-Women-Hanbok_1.jpg?v=1690724951',
      'https://joteta.com/cdn/shop/files/Traditional-Women-Hanbok_1.jpg?v=1690724951',
    ],
    'prod_018': [
      'https://hoaigiangshop.net/wp-content/uploads/2017/10/hanbok-nam-2.jpg',
      'https://hoaigiangshop.net/wp-content/uploads/2017/10/hanbok-nam-2.jpg',
    ],
    'prod_019': [
      'https://png.pngtree.com/png-vector/20251204/ourmid/pngtree-happy-young-korean-couple-in-hanbok-standing-on-white-background-real-png-image_18114527.webp',
      'https://png.pngtree.com/png-vector/20251204/ourmid/pngtree-happy-young-korean-couple-in-hanbok-standing-on-white-background-real-png-image_18114527.webp',
    ],
    'prod_020': [
      'http://aquashop.vn/Content/upload/DealSlide/3-12-2022/1153035312202221138561141.jpg',
      'http://aquashop.vn/Content/upload/DealSlide/3-12-2022/1153035312202221138561141.jpg',
    ],
    'prod_021': [
      'https://media.tripmap.vn/marketplace/2025/09/set-dong-phuc-hoc-sinh-nhat-ban-seifuku-jk-tay-ngan-vay-ngan-vay-dai-phong-cach-ngot-ngao-chinh-thong-1758416633-380x380.webp',
      'https://media.tripmap.vn/marketplace/2025/09/set-dong-phuc-hoc-sinh-nhat-ban-seifuku-jk-tay-ngan-vay-ngan-vay-dai-phong-cach-ngot-ngao-chinh-thong-1758416633-380x380.webp',
    ],
    'prod_022': [
      'https://congstudio.vn/wp-content/uploads/2023/06/Chup-anh-Sen-Ho-Tay-Uy-Tin-Chuyen-Nghiep-Gia-Re-1.jpg',
      'https://congstudio.vn/wp-content/uploads/2023/06/Chup-anh-Sen-Ho-Tay-Uy-Tin-Chuyen-Nghiep-Gia-Re-1.jpg',
    ],
    'prod_023': [
      'https://aodailianna.com/wp-content/uploads/2026/02/kiotviet_8efa577d9a17235da68b440e38ce4e8d.jpeg',
      'https://aodailianna.com/wp-content/uploads/2026/02/kiotviet_8efa577d9a17235da68b440e38ce4e8d.jpeg',
    ],
    'prod_024': [
      'https://product.hstatic.net/200000774833/product/cfb04e3b-02c8-41c4-82e6-86522b57eda6_51e95f667da54568a94d447cc6ac9455.jpeg',
      'https://product.hstatic.net/200000774833/product/cfb04e3b-02c8-41c4-82e6-86522b57eda6_51e95f667da54568a94d447cc6ac9455.jpeg',
    ],
    'prod_025': [
      'https://m.yodycdn.com/blog/ao-tu-than-yodyvn.jpg',
      'https://m.yodycdn.com/blog/ao-tu-than-yodyvn.jpg',
    ],
    'prod_026': [
      'https://p16-oec-va.ibyteimg.com/tos-maliva-i-o3syd03w52-us/bc080ca55492488498ebf3065efac999~tplv-o3syd03w52-resize-webp:800:800.webp?dr=15592&t=555f072d&ps=933b5bde&shp=8dbd94bf&shcp=607f11de&idc=my3&from=2378011839',
      'https://p16-oec-va.ibyteimg.com/tos-maliva-i-o3syd03w52-us/bc080ca55492488498ebf3065efac999~tplv-o3syd03w52-resize-webp:800:800.webp?dr=15592&t=555f072d&ps=933b5bde&shp=8dbd94bf&shcp=607f11de&idc=my3&from=2378011839',
    ],
    'prod_027': [
      'https://quatangngoctrai.com/wp-content/uploads/2026/01/Vong-Co-Ngoc-Trai-3-Tang-NE1083-2.jpg',
      'https://quatangngoctrai.com/wp-content/uploads/2026/01/Vong-Co-Ngoc-Trai-3-Tang-NE1083-2.jpg',
    ],
    'prod_028': [
      'https://encrypted-tbn3.gstatic.com/shopping?q=tbn:ANd9GcQN0H2duHiCorO8GUzXflL91aJT001GsF1_l7n8mWp8Bfo-a2FpmrsTs6ECGWBofcQtXHDXOCVkVC54h7EujRaWXb7f1enSvDonLr18LZKnIaBGMehF_NsyqRqmLEPp_FdXwffe3a4&usqp=CAc',
      'https://encrypted-tbn3.gstatic.com/shopping?q=tbn:ANd9GcQN0H2duHiCorO8GUzXflL91aJT001GsF1_l7n8mWp8Bfo-a2FpmrsTs6ECGWBofcQtXHDXOCVkVC54h7EujRaWXb7f1enSvDonLr18LZKnIaBGMehF_NsyqRqmLEPp_FdXwffe3a4&usqp=CAc',
    ],
    'prod_029': [
      'https://www.tierra.vn/wp-content/uploads/2025/06/khan-voan-lua.png',
      'https://www.tierra.vn/wp-content/uploads/2025/06/khan-voan-lua.png',
    ],
    'prod_030': [
      'https://encrypted-tbn0.gstatic.com/shopping?q=tbn:ANd9GcSIjDGQZZbAdsxqk6MK2tLA2NZnU4oW9AfyANKCcv7LCXQGQu-r3vAt3q_LcP28w7XbQaJpepDuF-6SyPmmGR_3h-MwVDRfy3XGa9mtYQSCJJfckg5O6zh92BxuFyOc1H_HBvBezg&usqp=CAc',
      'https://encrypted-tbn0.gstatic.com/shopping?q=tbn:ANd9GcSIjDGQZZbAdsxqk6MK2tLA2NZnU4oW9AfyANKCcv7LCXQGQu-r3vAt3q_LcP28w7XbQaJpepDuF-6SyPmmGR_3h-MwVDRfy3XGa9mtYQSCJJfckg5O6zh92BxuFyOc1H_HBvBezg&usqp=CAc',
    ],
  };

  /// Chạy hàm này để cập nhật URLs lên Firestore
  static Future<void> execute() async {
    debugPrint('🖼️ Bắt đầu cập nhật link ảnh...');

    // Cập nhật Chi nhánh
    for (final entry in branchImageUrls.entries) {
      if (entry.value.isEmpty || entry.value.contains('link-anh-')) {
        continue;
      }

      await _db
          .collection(AppConstants.branchesCollection)
          .doc(entry.key)
          .update({'imageUrl': entry.value});
      debugPrint('Đã cập nhật ảnh cho chi nhánh: ${entry.key}');
    }

    // Cập nhật Sản phẩm
    for (final entry in productImages.entries) {
      final List<String> urls = entry.value;
      if (urls.isEmpty ||
          urls.first.isEmpty ||
          urls.first.contains('link-thumbnail-')) {
        continue;
      }

      final String thumbUrl = urls.first;
      final List<String> detailUrls = urls.length > 1 ? urls.sublist(1) : [];

      await _db
          .collection(AppConstants.productsCollection)
          .doc(entry.key)
          .update({
            'thumbnailUrl': thumbUrl,
            'imageUrls':
                detailUrls, // Chỉ ghi đè nếu muốn, hoặc bạn đổi lại kịch bản
          });
      debugPrint('Đã cập nhật ảnh cho sản phẩm: ${entry.key}');
    }

    debugPrint('🎉 CẬP NHẬT ẢNH HOÀN TẤT!');
  }
}
