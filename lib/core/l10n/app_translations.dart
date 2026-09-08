import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maktaba_ihsan/core/providers/settings_provider.dart';

final translationProvider = Provider<AppTranslations>((ref) {
  final locale = ref.watch(appSettingsProvider).locale.languageCode;
  return AppTranslations(locale);
});

class AppTranslations {
  final String locale;
  AppTranslations(this.locale);

  bool get isBengali => locale == 'bn';

  String get appTitle => _get({
        'bn': 'মাকতাবাতুল ইহসান',
        'en': 'Maktabatu Ihsan',
        'ar': 'مكتبة الإحسان',
        'ur': 'مکتبۃ الاحسان'
      });
  String get memberProfile => _get({
        'bn': 'সদস্যের প্রোফাইল',
        'en': 'Member Profile',
        'ar': 'ملف العضو',
        'ur': 'ممبر پروفائل'
      });
  String get print => _get(
      {'bn': 'প্রিন্ট করুন', 'en': 'Print', 'ar': 'طباعة', 'ur': 'پرنٹ کریں'});
  String get issueBook => _get({
        'bn': 'কিতাব ইস্যু করুন',
        'en': 'Issue Book',
        'ar': 'إصدار كتاب',
        'ur': 'کتاب جاری کریں'
      });
  String get currentlyIssued => _get({
        'bn': 'বর্তমানে আছে',
        'en': 'Currently Issued',
        'ar': 'مُصدر حاليا',
        'ur': 'فی الحال جاری'
      });
  String get returned => _get({
        'bn': 'ফেরত দেওয়া হয়েছে',
        'en': 'Returned',
        'ar': 'تم الإرجاع',
        'ur': 'واپس کر دیا گیا'
      });
  String get takeReturn => _get({
        'bn': 'ফেরত নিন',
        'en': 'Return Book',
        'ar': 'استرجاع',
        'ur': 'کتاب واپس لیں'
      });
  String get active =>
      _get({'bn': 'সক্রিয়', 'en': 'Active', 'ar': 'نشط', 'ur': 'فعال'});
  String get inactive => _get(
      {'bn': 'নিষ্ক্রিয়', 'en': 'Inactive', 'ar': 'غير نشط', 'ur': 'غیر فعال'});
  String get classJamat => _get({
        'bn': 'শ্রেণী',
        'en': 'Class',
        'ar': 'الصف',
        'ur': 'کلاس'
      });
  String get phone =>
      _get({'bn': 'মোবাইল:', 'en': 'Phone:', 'ar': 'الهاتف:', 'ur': 'فون:'});
  String get unknownBook => _get({
        'bn': 'অজানা কিতাব',
        'en': 'Unknown Book',
        'ar': 'كتاب غير معروف',
        'ur': 'نامعلوم کتاب'
      });
  String get loading => _get({
        'bn': 'লোড হচ্ছে...',
        'en': 'Loading...',
        'ar': 'جاري التحميل...',
        'ur': 'لوڈ ہو رہا ہے...'
      });
  String get error =>
      _get({'bn': 'ত্রুটি', 'en': 'Error', 'ar': 'خطأ', 'ur': 'خرابی'});
  String get issueDate => _get({
        'bn': 'নেওয়ার তারিখ:',
        'en': 'Issue Date:',
        'ar': 'تاريخ الإصدار:',
        'ur': 'جاری کرنے کی تاریخ:'
      });
  String get returnDate => _get({
        'bn': 'ফেরত দেওয়ার তারিখ:',
        'en': 'Return Date:',
        'ar': 'تاريخ الإرجاع:',
        'ur': 'واپسی کی تاریخ:'
      });

  String get requestDate => _get({
        'bn': 'অনুরোধের তারিখ:',
        'en': 'Request Date:',
        'ar': 'تاريخ الطلب:',
        'ur': 'درخواست کی تاریخ:'
      });

  String get daysOverdue => _get({
        'bn': 'দিন পার হয়েছে',
        'en': 'days overdue',
        'ar': 'أيام متأخرة',
        'ur': 'دن تاخیر کا شکار'
      });

  String get bookAccessionNo => _get({
        'bn': 'কিতাবের অ্যাকসেশন নম্বর',
        'en': 'Book Accession No',
        'ar': 'رقم وصول الكتاب',
        'ur': 'کتاب کا ایکشن نمبر'
      });
  String get memberId => _get({
        'bn': 'সদস্য আইডি',
        'en': 'Member ID',
        'ar': 'معرف العضو',
        'ur': 'ممبر آئی ڈی'
      });
  // String get issueDate => _get({'bn': 'ইস্যু করার তারিখ', 'en': 'Issue Date', 'ar': 'تاريخ الإصدار', 'ur': 'جاری کرنے کی تاریخ'});
  String get bookNotFound => _get({
        'bn': 'কিতাব পাওয়া যায়নি',
        'en': 'Book not found',
        'ar': 'لم يتم العثور على الكتاب',
        'ur': 'کتاب نہیں ملی'
      });
  String get searching => _get({
        'bn': 'খোঁজা হচ্ছে...',
        'en': 'Searching...',
        'ar': 'جاري البحث...',
        'ur': 'تلاش کی جا رہی ہے...'
      });

  // Transactions list
  String get requestApprovedIssue => _get({
        'bn': 'রিকোয়েস্ট অ্যাপ্রুভ করুন (ইস্যু করুন)',
        'en': 'Approve Request (Issue)',
        'ar': 'الموافقة على الطلب (إصدار)',
        'ur': 'درخواست منظور کریں (جاری کریں)'
      });
  String get bookReturned => _get({
        'bn': 'কিতাবটি ফেরত দেওয়া হয়েছে',
        'en': 'Book has been returned',
        'ar': 'تم إرجاع الكتاب',
        'ur': 'کتاب واپس کر دی گئی ہے'
      });
  String get statusRequested => _get({
        'bn': 'রিকোয়েস্ট করা হয়েছে',
        'en': 'Requested',
        'ar': 'مطلوب',
        'ur': 'درخواست کی گئی'
      });

  String get statusActive =>
      _get({'bn': 'সক্রিয়', 'en': 'Active', 'ar': 'نشط', 'ur': 'فعال'});
  String get statusInactive => _get(
      {'bn': 'নিষ্ক্রিয়', 'en': 'Inactive', 'ar': 'غير نشط', 'ur': 'غیر فعال'});
  String get required =>
      _get({'bn': 'আবশ্যক', 'en': 'Required', 'ar': 'مطلوب', 'ur': 'ضروری'});

  String get bookDamagedStatus =>
      _get({'bn': 'ক্ষতিগ্রস্ত', 'en': 'Damaged', 'ar': 'تالف', 'ur': 'خراب'});
  String get bookReferenceStatus =>
      _get({'bn': 'রেফারেন্স', 'en': 'Reference', 'ar': 'مرجع', 'ur': 'حوالہ'});

  String get pendingRequests => _get({
        'bn': 'পেন্ডিং রিকোয়েস্ট',
        'en': 'Pending Requests',
        'ar': 'الطلبات المعلقة',
        'ur': 'زیر التواء درخواستیں'
      });
  String get currentlyWithMe => _get({
        'bn': 'বর্তমানে আমার কাছে আছে',
        'en': 'Currently with me',
        'ar': 'حاليًا معي',
        'ur': 'فی الحال میرے پاس ہے'
      });
  String get previouslyRead => _get({
        'bn': 'আগে পড়েছি',
        'en': 'Previously Read',
        'ar': 'قرأتها سابقًا',
        'ur': 'پہلے پڑھی گئی'
      });
  String get accessionNo => _get({
        'bn': 'কিতাব নং',
        'en': 'Book No',
        'ar': 'رقم الكتاب',
        'ur': 'کتاب نمبر'
      });
  String get bookNumber => _get({
        'bn': 'কিতাব নং',
        'en': 'Book No',
        'ar': 'رقم الكتاب',
        'ur': 'کتاب نمبر'
      });
  String get noBooks => _get({
        'bn': 'কোনো কিতাব পাওয়া যায়নি',
        'en': 'No books found',
        'ar': 'لم يتم العثور على أي كتب',
        'ur': 'کوئی کتاب نہیں ملی'
      });
  String get pending => _get({
        'bn': 'পেন্ডিং',
        'en': 'Pending',
        'ar': 'قيد الانتظار',
        'ur': 'زیر التواء'
      });
  String get statusReturned => _get({
        'bn': 'ফেরত',
        'en': 'Returned',
        'ar': 'تم الإرجاع',
        'ur': 'واپس کیا گیا'
      });
  String get statusOverdue => _get({
        'bn': 'মেয়াদোত্তীর্ণ',
        'en': 'Overdue',
        'ar': 'متأخر',
        'ur': 'زائد المیعاد'
      });
  String get statusOngoing =>
      _get({'bn': 'চলমান', 'en': 'Ongoing', 'ar': 'مستمر', 'ur': 'جاری'});

  String get books => _get({'bn': 'কিতাবসমূহ', 'en': 'Books', 'ar': 'الكتب', 'ur': 'کتب'});
  String get status => _get({'bn': 'অবস্থা', 'en': 'Status', 'ar': 'الحالة', 'ur': 'حالت'});
  String get statusIssued => _get({'bn': 'ইস্যু করা হয়েছে', 'en': 'Issued', 'ar': 'مُصدر', 'ur': 'جاری کردہ'});

  String get name => _get({'bn': 'নাম', 'en': 'Name', 'ar': 'الاسم', 'ur': 'نام'});
  String get transactionList => _get({'bn': 'লেনদেনের তালিকা', 'en': 'Transaction List', 'ar': 'قائمة المعاملات', 'ur': 'معاملات کی فہرست'});

  String get selectDays => _get({'bn': 'দিন নির্বাচন করুন', 'en': 'Select Days', 'ar': 'حدد الأيام', 'ur': 'دن منتخب کریں'});
  String get alarmAndReminder => _get({'bn': 'অ্যালার্ম ও রিমাইন্ডার', 'en': 'Alarm & Reminder', 'ar': 'المنبه والتذكير', 'ur': 'الارم اور یاد دہانی'});
  String get alarmOff => _get({'bn': 'অ্যালার্ম বন্ধ', 'en': 'Alarm Off', 'ar': 'إيقاف المنبه', 'ur': 'الارم بند'});
  String get reminderNightBefore => _get({'bn': 'আগের দিন রাতে রিমাইন্ডার', 'en': 'Reminder the night before', 'ar': 'تذكير في الليلة السابقة', 'ur': 'ایک رات پہلے یاد دہانی'});
  String get reminderNightBeforeDesc => _get({'bn': 'বইটি জমা দেওয়ার আগের দিন রাতে আপনাকে স্মরণ করিয়ে দেওয়া হবে', 'en': 'You will be reminded the night before the book is due', 'ar': 'سيتم تذكيرك في الليلة السابقة لموعد تسليم الكتاب', 'ur': 'کتاب جمع کرانے سے ایک رات پہلے آپ کو یاد دلایا جائے گا'});
  String get saveBtn => _get({'bn': 'সেভ করুন', 'en': 'Save', 'ar': 'حفظ', 'ur': 'محفوظ کریں'});
  String get save => saveBtn;
  String get editTransaction => _get({'bn': 'লেনদেন এডিট করুন', 'en': 'Edit Transaction', 'ar': 'تعديل المعاملة', 'ur': 'معاملہ میں ترمیم کریں'});
  String get addTransaction => _get({'bn': 'নতুন লেনদেন', 'en': 'Add Transaction', 'ar': 'إضافة معاملة', 'ur': 'نیا معاملہ'});
  String get all => _get({'bn': 'সব', 'en': 'All', 'ar': 'الكل', 'ur': 'تمام'});
  String get noTransactions => _get({'bn': 'কোনো লেনদেন নেই', 'en': 'No Transactions', 'ar': 'لا توجد معاملات', 'ur': 'کوئی لین دین نہیں'});
  String get editUser => _get({'bn': 'সদস্য এডিট করুন', 'en': 'Edit Member', 'ar': 'تعديل العضو', 'ur': 'ممبر میں ترمیم کریں'});
  String get addUser => _get({'bn': 'নতুন সদস্য', 'en': 'Add Member', 'ar': 'إضافة عضو', 'ur': 'نیا ممبر'});
  String get idNumberLabel => _get({'bn': 'আইডি নম্বর', 'en': 'ID Number', 'ar': 'رقم الهوية', 'ur': 'آئی ڈی نمبر'});
  String get mobileNumberLabel => _get({'bn': 'মোবাইল নম্বর', 'en': 'Mobile Number', 'ar': 'رقم الهاتف المحمول', 'ur': 'موبائل نمبر'});
  String get newPinLabel => _get({'bn': 'নতুন পিন (ঐচ্ছিক)', 'en': 'New PIN (Optional)', 'ar': 'رقم تعريف شخصي جديد (اختياري)', 'ur': 'نیا پن (اختیاری)'});
  String get pinNumberLabel => _get({'bn': 'পিন নম্বর', 'en': 'PIN Number', 'ar': 'رقم التعريف الشخصي', 'ur': 'پن نمبر'});
  String get memberTypeLabel => _get({'bn': 'সদস্যের ধরন', 'en': 'Member Type', 'ar': 'نوع العضو', 'ur': 'ممبر کی قسم'});
  String get noMembers => _get({'bn': 'কোনো সদস্য নেই', 'en': 'No Members', 'ar': 'لا يوجد أعضاء', 'ur': 'کوئی ممبر نہیں'});
  String get admin => _get({'bn': 'অ্যাডমিন', 'en': 'Admin', 'ar': 'مسؤول', 'ur': 'ایڈمن'});
  String get principal => _get({'bn': 'প্রিন্সিপাল', 'en': 'Principal', 'ar': 'المدير', 'ur': 'پرنسپل'});
  String get educationSecretary => _get({'bn': 'শিক্ষা সচিব', 'en': 'Education Secretary', 'ar': 'أمين التعليم', 'ur': 'ناظم تعلیمات'});
  String get teacher => _get({'bn': 'শিক্ষক', 'en': 'Teacher', 'ar': 'معلم', 'ur': 'استاد'});
  String get student => _get({'bn': 'ছাত্র', 'en': 'Student', 'ar': 'طالب', 'ur': 'طالب علم'});
  String get titlePlaceholder => _get({'bn': 'শিরোনাম লিখুন', 'en': 'Enter Title', 'ar': 'أدخل العنوان', 'ur': 'عنوان درج کریں'});
  String get contentPlaceholder => _get({'bn': 'বিস্তারিত লিখুন', 'en': 'Enter Description', 'ar': 'أدخل الوصف', 'ur': 'تفصیل درج کریں'});

  String get myNotes => _get({'bn': 'আমার নোটস', 'en': 'My Notes', 'ar': 'ملاحظاتي', 'ur': 'میرے نوٹس'});
  String get noNotesFound => _get({'bn': 'কোনো নোট পাওয়া যায়নি', 'en': 'No notes found', 'ar': 'لم يتم العثور على ملاحظات', 'ur': 'کوئی نوٹس نہیں ملے'});
  String get untitled => _get({'bn': 'শিরোনামহীন', 'en': 'Untitled', 'ar': 'بدون عنوان', 'ur': 'بغیر عنوان'});
  String get share => _get({'bn': 'শেয়ার', 'en': 'Share', 'ar': 'مشاركة', 'ur': 'شیئر'});
  String get delete => _get({'bn': 'ডিলিট', 'en': 'Delete', 'ar': 'حذف', 'ur': 'حذف کریں'});

  String get mon => _get({'bn': 'সোম', 'en': 'Mon', 'ar': 'الاثنين', 'ur': 'پیر'});
  String get tue => _get({'bn': 'মঙ্গল', 'en': 'Tue', 'ar': 'الثلاثاء', 'ur': 'منگل'});
  String get wed => _get({'bn': 'বুধ', 'en': 'Wed', 'ar': 'الأربعاء', 'ur': 'بدھ'});
  String get thu => _get({'bn': 'বৃহঃ', 'en': 'Thu', 'ar': 'الخميس', 'ur': 'جمعرات'});
  String get fri => _get({'bn': 'শুক্র', 'en': 'Fri', 'ar': 'الجمعة', 'ur': 'جمعہ'});
  String get sat => _get({'bn': 'শনি', 'en': 'Sat', 'ar': 'السبت', 'ur': 'ہفتہ'});
  String get sun => _get({'bn': 'রবি', 'en': 'Sun', 'ar': 'الأحد', 'ur': 'اتوار'});

  String get addRoutine => _get({'bn': 'রুটিন যোগ করুন', 'en': 'Add Routine', 'ar': 'إضافة روتين', 'ur': 'روٹین شامل کریں'});
  String get roomNo => _get({'bn': 'রুম নং', 'en': 'Room No', 'ar': 'غرفة رقم', 'ur': 'کمرہ نمبر'});
  String get addNewRoutine => _get({'bn': 'নতুন রুটিন', 'en': 'New Routine', 'ar': 'روتين جديد', 'ur': 'نیا روٹین'});
  String get subjectLabel => _get({'bn': 'বিষয়', 'en': 'Subject', 'ar': 'الموضوع', 'ur': 'مضمون'});
  String get startTime => _get({'bn': 'শুরুর সময়', 'en': 'Start Time', 'ar': 'وقت البدء', 'ur': 'شروع کا وقت'});
  String get endTime => _get({'bn': 'শেষের সময়', 'en': 'End Time', 'ar': 'وقت الانتهاء', 'ur': 'ختم ہونے کا وقت'});

  String get addBookTitle => _get({'bn': 'বই যোগ করুন', 'en': 'Add Book', 'ar': 'إضافة كتاب', 'ur': 'کتاب شامل کریں'});
  String get addressLabel => _get({'bn': 'ঠিকানা', 'en': 'Address', 'ar': 'العنوان', 'ur': 'پتہ'});
  String get addressNoteLabel => _get({'bn': 'ঠিকানার নোট', 'en': 'Address Note', 'ar': 'ملاحظة العنوان', 'ur': 'پتہ نوٹ'});
  String get adminOptions => _get({'bn': 'অ্যাডমিন অপশন', 'en': 'Admin Options', 'ar': 'خيارات المسؤول', 'ur': 'ایڈمن اختیارات'});
  String get author => _get({'bn': 'লেখক', 'en': 'Author', 'ar': 'المؤلف', 'ur': 'مصنف'});
  String get basicInfo => _get({'bn': 'প্রাথমিক তথ্য', 'en': 'Basic Info', 'ar': 'معلومات أساسية', 'ur': 'بنیادی معلومات'});
  String get bookList => _get({'bn': 'বইয়ের তালিকা', 'en': 'Book List', 'ar': 'قائمة الكتب', 'ur': 'کتابوں کی فہرست'});
  String get bookNameLabel => _get({'bn': 'বইয়ের নাম', 'en': 'Book Name', 'ar': 'اسم الكتاب', 'ur': 'کتاب کا نام'});
  String get bookStatusAvailable => _get({'bn': 'উপলব্ধ', 'en': 'Available', 'ar': 'متاح', 'ur': 'دستیاب'});
  String get bookStatusIssued => _get({'bn': 'ইস্যু করা হয়েছে', 'en': 'Issued', 'ar': 'مُصدر', 'ur': 'جاری کردہ'});
  String get bookStatusLost => _get({'bn': 'হারানো', 'en': 'Lost', 'ar': 'مفقود', 'ur': 'گم شدہ'});
  String get category => _get({'bn': 'বিভাগ', 'en': 'Category', 'ar': 'الفئة', 'ur': 'زمرہ'});
  String get classRoutine => _get({'bn': 'ক্লাস রুটিন', 'en': 'Class Routine', 'ar': 'روتين الفصل', 'ur': 'کلاس روٹین'});
  String get condition => _get({'bn': 'অবস্থা', 'en': 'Condition', 'ar': 'الحالة', 'ur': 'حالت'});
  String get currentCondition => _get({'bn': 'বর্তমান অবস্থা', 'en': 'Current Condition', 'ar': 'الحالة الحالية', 'ur': 'موجودہ حالت'});
  String get editBook => _get({'bn': 'বই এডিট করুন', 'en': 'Edit Book', 'ar': 'تعديل الكتاب', 'ur': 'کتاب میں ترمیم کریں'});
  String get languageSetting => _get({'bn': 'ভাষা', 'en': 'Language', 'ar': 'اللغة', 'ur': 'زبان'});
  String get location => _get({'bn': 'অবস্থান', 'en': 'Location', 'ar': 'الموقع', 'ur': 'مقام'});
  String get logout => _get({'bn': 'লগআউট', 'en': 'Logout', 'ar': 'تسجيل الخروج', 'ur': 'لاگ آؤٹ'});
  String get logoutDesc => _get({'bn': 'অ্যাকাউন্ট থেকে লগআউট করুন', 'en': 'Logout from account', 'ar': 'تسجيل الخروج من الحساب', 'ur': 'اکاؤنٹ سے لاگ آؤٹ کریں'});
  String get management => _get({'bn': 'ব্যবস্থাপনা', 'en': 'Management', 'ar': 'إدارة', 'ur': 'انتظام'});
  String get members => _get({'bn': 'সদস্যগণ', 'en': 'Members', 'ar': 'الأعضاء', 'ur': 'ممبران'});
  String get membersList => _get({'bn': 'সদস্য তালিকা', 'en': 'Members List', 'ar': 'قائمة الأعضاء', 'ur': 'ممبران کی فہرست'});
  String get inactiveMembersList => _get({'bn': 'নিষ্ক্রিয় সদস্য তালিকা', 'en': 'Inactive Members List', 'ar': 'قائمة الأعضاء غير النشطين', 'ur': 'غیر فعال ممبران کی فہرست'});
  String get backToActiveMembers => _get({'bn': 'সক্রিয় সদস্য তালিকায় ফিরুন', 'en': 'Back to Active Members', 'ar': 'العودة إلى قائمة النشطين', 'ur': 'فعال ممبران کی فہرست میں واپس جائیں'});
  String get noInactiveMembers => _get({'bn': 'কোনো নিষ্ক্রিয় সদস্য নেই', 'en': 'No inactive members', 'ar': 'لا يوجد أعضاء غير نشطين', 'ur': 'کوئی غیر فعال ممبر نہیں'});
  String get myShelf => _get({'bn': 'আমার শেলফ', 'en': 'My Shelf', 'ar': 'رفي', 'ur': 'میرا شیلف'});
  String get newNote => _get({'bn': 'নতুন নোট', 'en': 'New Note', 'ar': 'ملاحظة جديدة', 'ur': 'نیا نوٹ'});
  String get notesNav => _get({'bn': 'নোটস', 'en': 'Notes', 'ar': 'ملاحظات', 'ur': 'نوٹس'});
  String get personalNotes => _get({'bn': 'ব্যক্তিগত নোটস', 'en': 'Personal Notes', 'ar': 'ملاحظات شخصية', 'ur': 'ذاتی نوٹس'});
  String get publisher => _get({'bn': 'প্রকাশক', 'en': 'Publisher', 'ar': 'الناشر', 'ur': 'ناشر'});
  String get remarksLabel => _get({'bn': 'মন্তব্য', 'en': 'Remarks', 'ar': 'ملاحظات', 'ur': 'تبصرے'});
  String get requestThisBook => _get({'bn': 'এই বইটি রিকোয়েস্ট করুন', 'en': 'Request this book', 'ar': 'طلب هذا الكتاب', 'ur': 'اس کتاب کی درخواست کریں'});
  String get routineNav => _get({'bn': 'রুটিন', 'en': 'Routine', 'ar': 'روتين', 'ur': 'روٹین'});
  String get searchHint => _get({'bn': 'সার্চ করুন...', 'en': 'Search...', 'ar': 'بحث...', 'ur': 'تلاش کریں...'});
  String get searchNav => _get({'bn': 'সার্চ', 'en': 'Search', 'ar': 'بحث', 'ur': 'تلاش کریں'});
  String get settings => _get({'bn': 'সেটিংস', 'en': 'Settings', 'ar': 'الإعدادات', 'ur': 'ترتیبات'});
  String get shelfNav => _get({'bn': 'শেলফ', 'en': 'Shelf', 'ar': 'رف', 'ur': 'شیلف'});
  String get shelfNo => _get({'bn': 'শেলফ নং', 'en': 'Shelf No', 'ar': 'رقم الرف', 'ur': 'شیلف نمبر'});
  String get shelfNoLabel => _get({'bn': 'শেলফ নং', 'en': 'Shelf No', 'ar': 'رقم الرف', 'ur': 'شیلف نمبر'});
  String get teacherDashboardDesc => _get({'bn': 'শিক্ষকদের জন্য বিশেষ ড্যাশবোর্ড ব্যবহার করুন', 'en': 'Use special dashboard for teachers', 'ar': 'استخدام لوحة تحكم خاصة للمعلمين', 'ur': 'اساتذہ کے لیے خصوصی ڈیش بورڈ استعمال کریں'});
  String get themeSetting => _get({'bn': 'থিম', 'en': 'Theme', 'ar': 'السمة', 'ur': 'تھیم'});
  String get transactions => _get({'bn': 'লেনদেন', 'en': 'Transactions', 'ar': 'المعاملات', 'ur': 'معاملات'});
  String get transactionTab => _get({'bn': 'লেনদেন', 'en': 'Transactions', 'ar': 'المعاملات', 'ur': 'معاملات'});
  String get translatorLabel => _get({'bn': 'অনুবাদক / মুহাক্কিক', 'en': 'Translator / Editor', 'ar': 'المترجم / المحقق', 'ur': 'مترجم / محقق'});
  String get useTeacherDashboard => _get({'bn': 'শিক্ষক ড্যাশবোর্ড', 'en': 'Teacher Dashboard', 'ar': 'لوحة تحكم المعلم', 'ur': 'استاد کا ڈیش بورڈ'});
  String get volumeNoLabel => _get({'bn': 'খন্ড নং', 'en': 'Volume No', 'ar': 'رقم المجلد', 'ur': 'جلد نمبر'});

  String get noRoutineToday => _get({'bn': 'আজকের কোনো রুটিন নেই', 'en': 'No routine for today', 'ar': 'لا يوجد روتين لهذا اليوم', 'ur': 'آج کا کوئی روٹین نہیں ہے'});
  String get addRoutinePrompt => _get({'bn': 'নতুন রুটিন যোগ করতে নিচের বাটনে ক্লিক করুন', 'en': 'Click the button below to add a routine', 'ar': 'انقر على الزر أدناه لإضافة روتين', 'ur': 'نیا روٹین شامل کرنے کے لیے نیچے دیے گئے بٹن پر کلک کریں'});
  String get editRoutine => _get({'bn': 'রুটিন এডিট করুন', 'en': 'Edit Routine', 'ar': 'تعديل الروتين', 'ur': 'روٹین میں ترمیم کریں'});
  String get deleteRoutineConfirm => _get({'bn': 'আপনি কি এই রুটিনটি মুছে ফেলতে চান?', 'en': 'Do you want to delete this routine?', 'ar': 'هل تريد بالتأكيد حذف هذا الروتين؟', 'ur': 'کیا آپ واقعی اس روٹین کو حذف کرنا چاہتے ہیں؟'});
  String get classesCount => _get({'bn': 'টি ক্লাস', 'en': 'Classes', 'ar': 'حصص', 'ur': 'کلاسز'});
  String get cancel => _get({'bn': 'বাতিল', 'en': 'Cancel', 'ar': 'إلغاء', 'ur': 'منسوخ'});
  String get periodNumberLabel => _get({'bn': 'ঘণ্টা / দরস নং', 'en': 'Period / Hour No.', 'ar': 'رقم الحصة / الدرس', 'ur': 'گھنٹہ / پیریڈ نمبر'});
  String get periodNumberHint => _get({'bn': 'যেমন: ১ম ঘণ্টা', 'en': 'e.g. 1st Period', 'ar': 'مثال: الحصة الأولى', 'ur': 'مثال: پہلا گھنٹہ'});

  String get allAuthors => _get({'bn': 'সব লেখক', 'en': 'All Authors', 'ar': 'جميع المؤلفين', 'ur': 'تمام مصنفین'});
  String get allPublishers => _get({'bn': 'সব প্রকাশক/মাকতাবা', 'en': 'All Publishers', 'ar': 'جميع دور النشر', 'ur': 'تمام ناشرین'});
  String get allSubjects => _get({'bn': 'সব বিষয়', 'en': 'All Subjects', 'ar': 'جميع الموضوعات', 'ur': 'تمام مضامین'});
  String get allShelves => _get({'bn': 'সব শেলফ', 'en': 'All Shelves', 'ar': 'جميع الرفوف', 'ur': 'تمام شیلف'});
  String get selectAuthor => _get({'bn': 'লেখক নির্বাচন করুন', 'en': 'Select Author', 'ar': 'اختر المؤلف', 'ur': 'مصنف منتخب کریں'});
  String get selectPublisher => _get({'bn': 'প্রকাশক/মাকতাবা নির্বাচন করুন', 'en': 'Select Publisher', 'ar': 'اختر دار النشر', 'ur': 'ناشر منتخب کریں'});
  String get selectCategory => _get({'bn': 'বিষয়/বিভাগ নির্বাচন করুন', 'en': 'Select Category', 'ar': 'اختر الفئة', 'ur': 'زمرہ منتخب کریں'});
  String get selectShelf => _get({'bn': 'শেলফ নির্বাচন করুন', 'en': 'Select Shelf', 'ar': 'اختر الرف', 'ur': 'شیلف منتخب کریں'});
  String get clearFilters => _get({'bn': 'ফিল্টার মুছুন', 'en': 'Clear Filters', 'ar': 'إزالة الفلاتর', 'ur': 'فلٹرز ختم کریں'});
  String get filterLabel => _get({'bn': 'ফিল্টার', 'en': 'Filter', 'ar': 'تصفية', 'ur': 'فلٹر'});
  String get booksFound => _get({'bn': 'টি কিতাব পাওয়া গেছে', 'en': 'books found', 'ar': 'كتب موجودة', 'ur': 'کتب دستیاب ہیں'});
  String get searchInFilter => _get({'bn': 'খুঁজুন...', 'en': 'Search...', 'ar': 'بحث...', 'ur': 'تلاش کریں...'});

  // ── Numbers & Digits Formatter ──────────────────────────────────────────
  String formatNumber(dynamic n) {
    final s = n.toString();
    if (locale == 'bn') {
      const bn = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
      return s.split('').map((c) {
        final idx = int.tryParse(c);
        return idx != null ? bn[idx] : c;
      }).join('');
    } else if (locale == 'ar') {
      const ar = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
      return s.split('').map((c) {
        final idx = int.tryParse(c);
        return idx != null ? ar[idx] : c;
      }).join('');
    } else if (locale == 'ur') {
      const ur = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
      return s.split('').map((c) {
        final idx = int.tryParse(c);
        return idx != null ? ur[idx] : c;
      }).join('');
    }
    return s;
  }

  // ── Assets & Equipment ──────────────────────────────────────────────────
  String get assetsNav => _get({'bn': 'মালামাল', 'en': 'Assets', 'ar': 'المقتنيات', 'ur': 'سامان'});
  String get assetsAndEquipment => _get({'bn': 'মালামাল ও সরঞ্জাম', 'en': 'Assets & Equipment', 'ar': 'المقتنيات والتجهيزات', 'ur': 'سامان اور سازوسامان'});
  String get assetDetails => _get({'bn': 'মালামালের বিবরণ', 'en': 'Asset Details', 'ar': 'تفاصيل المقتنى', 'ur': 'سامان کی تفصیلات'});
  String get addNewAsset => _get({'bn': 'নতুন মালামাল যোগ করুন', 'en': 'Add New Asset', 'ar': 'إضافة مقتنى جديد', 'ur': 'نیا سامان شامل کریں'});
  String get editAsset => _get({'bn': 'মালামাল এডিট করুন', 'en': 'Edit Asset', 'ar': 'تعديل المقتنى', 'ur': 'سامان میں ترمیم کریں'});

  String get searchAssetsHint => _get({'bn': 'মালামাল, অবস্থান বা দাতা খুঁজুন...', 'en': 'Search assets, location or donor...', 'ar': 'البحث في المقتنيات أو الموقع أو الواهب...', 'ur': 'سامان، مقام یا عطیہ دہندہ تلاش کریں...'});
  String get filterCategory => _get({'bn': 'বিভাগ', 'en': 'Category', 'ar': 'القسم', 'ur': 'شعبہ'});
  String get changeCategory => _get({'bn': 'বিভাগ পরিবর্তন করুন', 'en': 'Change Category', 'ar': 'تغيير القسم', 'ur': 'شعبہ تبدیل کریں'});
  String get allCategories => _get({'bn': 'সব বিভাগ', 'en': 'All Categories', 'ar': 'جميع الأقسام', 'ur': 'تمام شعبہ جات'});
  String get loadingCategories => _get({'bn': 'বিভাগ লোড হচ্ছে...', 'en': 'Loading categories...', 'ar': 'جارٍ تحميل الأقسام...', 'ur': 'شعبہ جات لوڈ ہو رہے ہیں...'});
  String get noCategoriesFound => _get({'bn': 'কোনো বিভাগ পাওয়া যায়নি', 'en': 'No categories found', 'ar': 'لم يتم العثور على أقسام', 'ur': 'کوئی شعبہ نہیں ملا'});
  String get activeFiltersLabel => _get({'bn': 'সক্রিয় ফিল্টার:', 'en': 'Active Filters:', 'ar': 'التصفيات النشطة:', 'ur': 'فعال فلٹرز:'});
  String get clearAll => _get({'bn': 'সব মুছুন', 'en': 'Clear All', 'ar': 'مسح الكل', 'ur': 'سب صاف کریں'});
  String get resetFilters => _get({'bn': 'ফিল্টার রিসেট করুন', 'en': 'Reset Filters', 'ar': 'إعادة ضبط التصفيات', 'ur': 'فلٹرز دوبارہ ترتیب دیں'});
  String get noAssetsToPrint => _get({'bn': 'প্রিন্ট করার মতো কোনো মালামাল নেই', 'en': 'No assets to print', 'ar': 'لا توجد مقتنيات للطباعة', 'ur': 'پرنٹ کرنے کے لیے کوئی سامان نہیں'});

  String get edit => _get({'bn': 'এডিট করুন', 'en': 'Edit', 'ar': 'تعديل', 'ur': 'ترمیم کریں'});
  String get categoryLabel => _get({'bn': 'বিভাগ / ক্যাটাগরি', 'en': 'Category', 'ar': 'القسم / الفئة', 'ur': 'شعبہ / زمرہ'});
  String get piecesUnit => _get({'bn': 'টি', 'en': 'pcs', 'ar': 'قطعة', 'ur': 'عدد'});
  String get totalAssets => _get({'bn': 'মোট মালামাল', 'en': 'Total Assets', 'ar': 'إجمالي المقتنيات', 'ur': 'کل سامان'});
  String get itemsCountUnit => _get({'bn': 'পদ', 'en': 'items', 'ar': 'بند', 'ur': 'اقسام'});
  String get conditionGood => _get({'bn': 'ভালো', 'en': 'Good', 'ar': 'جيد', 'ur': 'اچھا'});
  String get conditionGoodSub => _get({'bn': 'ব্যবহারযোগ্য', 'en': 'Usable', 'ar': 'صالح للاستخدام', 'ur': 'قابل استعمال'});
  String get conditionRepair => _get({'bn': 'মেরামত', 'en': 'Repair', 'ar': 'إصلاح', 'ur': 'مرمت'});
  String get conditionRepairSub => _get({'bn': 'রক্ষণাবেক্ষণ', 'en': 'Maintenance', 'ar': 'صيانة', 'ur': 'دیکھ بھال'});
  String get conditionDamaged => _get({'bn': 'নষ্ট/বাতিল', 'en': 'Damaged', 'ar': 'تالف', 'ur': 'خراب/متروک'});
  String get conditionDamagedSub => _get({'bn': 'অনুপযোগী', 'en': 'Unusable', 'ar': 'غير صالح', 'ur': 'ناقابل استعمال'});

  String get noAssetsMatched => _get({'bn': 'কোনো মালামাল মেলেনি', 'en': 'No assets matched', 'ar': 'لم يتم العثور على مقتنيات مطابقة', 'ur': 'کوئی مماثل سامان نہیں ملا'});
  String get noAssetsEntered => _get({'bn': 'কোনো মালামাল এন্ট্রি করা হয়নি', 'en': 'No assets recorded yet', 'ar': 'لم يتم تسجيل أي مقتنيات بعد', 'ur': 'ابھی تک کوئی سامان درج نہیں کیا گیا'});
  String get changeSearchFilterHint => _get({'bn': 'অনুসন্ধান বা ফিল্টারের শর্ত পরিবর্তন করে চেষ্টা করুন', 'en': 'Try adjusting your search or filters', 'ar': 'جرب تغيير شروط البحث أو التصفية', 'ur': 'تلاش یا فلٹر کی شرائط بدل کر کوشش کریں'});
  String get assetEmptyPrompt => _get({'bn': 'মাকতাবার আসবাবপত্র, আলমারি, বুকশেলফ বা ইলেকট্রনিক্স সরঞ্জাম সংরক্ষণ করুন', 'en': 'Keep track of furniture, bookshelves, electronics, and supplies', 'ar': 'سجل أثاث المكتبة والرفوف والإلكترونيات والتجهيزات', 'ur': 'مکتبہ کا فرنیچر، الماریاں، بک شیلف اور الیکٹرانکس محفوظ کریں'});

  String get assetInfoAndSpecs => _get({'bn': 'মালামালের বিবরণ ও তথ্য', 'en': 'Asset Specifications & Details', 'ar': 'مواصفات وبيانات المقتنى', 'ur': 'سامان کی تفصیلات اور معلومات'});
  String get locationLabel => _get({'bn': 'অবস্থান (কোথায় আছে)', 'en': 'Location (Where kept)', 'ar': 'الموقع (مكان التواجد)', 'ur': 'مقام (کہاں رکھا ہے)'});
  String get assetIdLabel => _get({'bn': 'মালামাল আইডি (Code)', 'en': 'Asset ID (Code)', 'ar': 'معرف المقتنى (الكود)', 'ur': 'سامان کا شناختی کوڈ'});
  String get donorNameLabel => _get({'bn': 'দাতার নাম (ওয়াকফকারী)', 'en': 'Donor Name (Waqf)', 'ar': 'اسم الواهب (الواقف)', 'ur': 'عطیہ دہندہ کا نام (واقف)'});
  String get sourceStoreLabel => _get({'bn': 'ক্রয়ের উৎস / দোকান', 'en': 'Purchase Source / Store', 'ar': 'مصدر الشراء / المتجر', 'ur': 'خریداری کا ذریعہ / دکان'});
  String get costLabel => _get({'bn': 'আনুমানিক মূল্য / খরচ', 'en': 'Estimated Cost / Value', 'ar': 'القيمة التقديرية / التكلفة', 'ur': 'تخمینی قیمت / خرچ'});
  String get acquisitionDateLabel => _get({'bn': 'সংগ্রহের তারিখ', 'en': 'Acquisition Date', 'ar': 'تاريخ الاقتناء', 'ur': 'حصول کی تاریخ'});
  String get remarksDetailLabel => _get({'bn': 'মন্তব্য / বিবরণ:', 'en': 'Remarks / Details:', 'ar': 'ملاحظات / تفاصيل:', 'ur': 'تبصرے / تفصیلات:'});
  String get changeCurrentCondition => _get({'bn': 'বর্তমান অবস্থা পরিবর্তন করুন:', 'en': 'Change Current Condition:', 'ar': 'تغيير الحالة الحالية:', 'ur': 'موجودہ حالت تبدیل کریں:'});
  String get deleteAssetConfirmTitle => _get({'bn': 'মালামাল মুছে ফেলা', 'en': 'Delete Asset', 'ar': 'حذف المقتنى', 'ur': 'سامان حذف کریں'});
  String get deleteAssetConfirmMsg => _get({'bn': 'আপনি কি নিশ্চিত যে এই মালামালটি তালিকা থেকে স্থায়ীভাবে মুছে ফেলতে চান?', 'en': 'Are you sure you want to permanently delete this asset?', 'ar': 'هل أنت متأكد من رغبتك في حذف هذا المقتنى نهائياً؟', 'ur': 'کیا آپ واقعی اس سامان کو مستقل طور پر حذف کرنا چاہتے ہیں؟'});
  String get deleteAssetSuccess => _get({'bn': 'মালামাল সফলভাবে মুছে ফেলা হয়েছে', 'en': 'Asset deleted successfully', 'ar': 'تم حذف المقتنى بنجاح', 'ur': 'سامان کامیابی سے حذف کر دیا گیا'});
  String get waqfLabel => _get({'bn': 'ওয়াকফ', 'en': 'Waqf', 'ar': 'وقف', 'ur': 'وقف'});
  String get waqfDonated => _get({'bn': 'ওয়াকফকৃত', 'en': 'Waqf Donated', 'ar': 'موقوف', 'ur': 'وقف شدہ'});
  String get purchasedLabel => _get({'bn': 'ক্রয়কৃত', 'en': 'Purchased', 'ar': 'مشترى', 'ur': 'خریدا گیا'});

  String get assetNameLabel => _get({'bn': 'মালামালের নাম *', 'en': 'Asset Name *', 'ar': 'اسم المقتنى *', 'ur': 'سامان کا نام *'});
  String get assetNameHint => _get({'bn': 'যেমন: বড় কাঠের বুকশেলফ, অফিস চেয়ার, প্রিন্টার', 'en': 'e.g., Wooden Bookshelf, Office Chair, Printer', 'ar': 'مثال: رف كتب خشبي، كرسي مكتب، طابعة', 'ur': 'مثلاً: لکڑی کا بک شیلف، دفتری کرسی، پرنٹر'});
  String get assetNameRequired => _get({'bn': 'দয়া করে মালামালের নাম লিখুন', 'en': 'Please enter asset name', 'ar': 'يرجى إدخال اسم المقتنى', 'ur': 'براہ کرم سامان کا نام درج کریں'});
  String get quantityLabel => _get({'bn': 'পরিমাণ *', 'en': 'Quantity *', 'ar': 'الكمية *', 'ur': 'تعداد *'});
  String get quantityRequired => _get({'bn': 'পরিমাণ দিন', 'en': 'Enter quantity', 'ar': 'أدخل الكمية', 'ur': 'تعداد درج کریں'});
  String get invalidNumber => _get({'bn': 'সঠিক সংখ্যা দিন', 'en': 'Enter a valid number', 'ar': 'أدخل رقماً صحيحاً', 'ur': 'درست عدد درج کریں'});
  String get unitLabel => _get({'bn': 'একক', 'en': 'Unit', 'ar': 'الوحدة', 'ur': 'اکائی'});
  String get locationFieldLabel => _get({'bn': 'কোথায় রাখা আছে (অবস্থান) *', 'en': 'Location (Where kept) *', 'ar': 'مكان التواجد *', 'ur': 'کہاں رکھا ہے (مقام) *'});
  String get locationFieldHint => _get({'bn': 'যেমন: মাকতাবা রুম-১, উত্তর দেয়াল, বুকশেলফ-৩', 'en': 'e.g., Room 1, North Wall, Shelf 3', 'ar': 'مثال: غرفة 1، الجدار الشمالي، الرف 3', 'ur': 'مثلاً: کمرہ 1، شمالی دیوار، بک شیلف 3'});
  String get locationRequired => _get({'bn': 'দয়া করে মালামালের অবস্থান উল্লেখ করুন', 'en': 'Please specify location', 'ar': 'يرجى تحديد مكان التواجد', 'ur': 'براہ کرم سامان کا مقام درج کریں'});
  String get currentConditionLabel => _get({'bn': 'বর্তমান অবস্থা:', 'en': 'Current Condition:', 'ar': 'الحالة الحالية:', 'ur': 'موجودہ حالت:'});
  String get repairNeededLabel => _get({'bn': 'মেরামত প্রয়োজন', 'en': 'Repair Needed', 'ar': 'يحتاج إلى إصلاح', 'ur': 'مرمت کی ضرورت ہے'});
  String get damagedOrDisposedLabel => _get({'bn': 'নষ্ট / বাতিল', 'en': 'Damaged / Disposed', 'ar': 'تالف / ملغى', 'ur': 'خراب / متروک'});
  String get acquisitionTypeLabel => _get({'bn': 'সংগ্রহের ধরন:', 'en': 'Acquisition Type:', 'ar': 'نوع الاقتناء:', 'ur': 'حصول کی قسم:'});
  String get donorOrSourceWaqfLabel => _get({'bn': 'দাতার নাম / উৎস', 'en': 'Donor Name / Source', 'ar': 'اسم الواهب / المصدر', 'ur': 'عطیہ دہندہ / ذریعہ'});
  String get donorOrSourcePurchaseLabel => _get({'bn': 'ক্রয়ের উৎস / দোকানের নাম', 'en': 'Purchase Source / Store Name', 'ar': 'مصدر الشراء / اسم المتجر', 'ur': 'خریداری کا ذریعہ / دکان کا نام'});
  String get donorOrSourceWaqfHint => _get({'bn': 'যেমন: আলহাজ্ব মাওলানা আব্দুর রহমান সাহেব', 'en': 'e.g., Alhaj Maulana Abdur Rahman', 'ar': 'مثال: الحاج مولانا عبد الرحمن', 'ur': 'مثلاً: الحاج مولانا عبد الرحمن صاحب'});
  String get donorOrSourcePurchaseHint => _get({'bn': 'যেমন: স্টেডিয়াম মার্কেট, ঢাকা', 'en': 'e.g., Stadium Market, Dhaka', 'ar': 'مثال: سوق الاستاد، دكا', 'ur': 'مثلاً: اسٹیڈیم مارکیٹ، ڈھاکہ'});
  String get costFieldLabel => _get({'bn': 'আনুমানিক মূল্য / খরচ (ঐচ্ছিক)', 'en': 'Estimated Cost / Value (Optional)', 'ar': 'التكلفة التقديرية / القيمة (اختياري)', 'ur': 'تخمینی قیمت / خرچ (اختیاری)'});
  String get remarksFieldLabel => _get({'bn': 'মন্তব্য / অতিরিক্ত বিবরণ (ঐচ্ছিক)', 'en': 'Remarks / Additional Details (Optional)', 'ar': 'ملاحظات / تفاصيل إضافية (اختياري)', 'ur': 'تبصرے / اضافی تفصیلات (اختیاری)'});
  String get remarksFieldHint => _get({'bn': 'মালামাল সংক্রান্ত কোনো বিশেষ দ্রষ্টব্য থাকলে লিখুন...', 'en': 'Any special notes regarding the asset...', 'ar': 'أي ملاحظات خاصة بالمقتنى...', 'ur': 'سامان کے حوالے سے کوئی خاص نوٹ لکھیں...'});
  String get saveAssetBtn => _get({'bn': 'মালামাল যুক্ত করুন', 'en': 'Add Asset', 'ar': 'حفظ المقتنى', 'ur': 'سامان شامل کریں'});
  String get updateAssetBtn => _get({'bn': 'আপডেট সংরক্ষণ করুন', 'en': 'Save Changes', 'ar': 'حفظ التعديلات', 'ur': 'تبدیلیاں محفوظ کریں'});
  String get saveAssetSuccess => _get({'bn': 'নতুন মালামাল সফলভাবে যুক্ত হয়েছে', 'en': 'New asset added successfully', 'ar': 'تمت إضافة المقتنى الجديد بنجاح', 'ur': 'نیا سامان کامیابی سے شامل کر دیا گیا'});
  String get updateAssetSuccess => _get({'bn': 'মালামালের তথ্য সফলভাবে আপডেট হয়েছে', 'en': 'Asset updated successfully', 'ar': 'تم تحديث بيانات المقتنى بنجاح', 'ur': 'سامان کی تفصیلات کامیابی سے اپ ڈیٹ ہو گئیں'});

  String translateCategory(String cat) {
    if (cat.contains('আসবাবপত্র') || cat.toLowerCase().contains('furniture')) {
      return _get({'bn': 'আসবাবপত্র', 'en': 'Furniture', 'ar': 'أثاث', 'ur': 'فرنیچر'});
    }
    if (cat.contains('ইলেকট্রনিক্স') || cat.toLowerCase().contains('electronics')) {
      return _get({'bn': 'ইলেকট্রনিক্স ও প্রযুক্তি', 'en': 'Electronics & Tech', 'ar': 'إلكترونيات وتكنولوجيا', 'ur': 'الیکٹرانکس و ٹیکنالوجی'});
    }
    if (cat.contains('বই') || cat.toLowerCase().contains('book')) {
      return _get({'bn': 'বই সংরক্ষণ ও বাঁধাই', 'en': 'Book Care & Binding', 'ar': 'حفظ الكتب وتجليدها', 'ur': 'کتابوں کی حفاظت اور جلد بندی'});
    }
    if (cat.contains('স্টেশনারি') || cat.toLowerCase().contains('stationery')) {
      return _get({'bn': 'স্টেশনারি ও অফিস', 'en': 'Stationery & Office', 'ar': 'قرطاسية ومكتب', 'ur': 'اسٹیشنری اور دفتر'});
    }
    if (cat.contains('পরিচ্ছন্নতা') || cat.toLowerCase().contains('cleaning')) {
      return _get({'bn': 'পরিচ্ছন্নতা ও অন্যান্য', 'en': 'Cleaning & Supplies', 'ar': 'نظافة ومستلزمات', 'ur': 'صفائی اور دیگر'});
    }
    return cat;
  }

  String translateUnit(String unit) {
    if (unit == 'টি' || unit.toLowerCase() == 'pcs' || unit.toLowerCase() == 'piece') {
      return _get({'bn': 'টি', 'en': 'pcs', 'ar': 'قطعة', 'ur': 'عدد'});
    }
    if (unit == 'সেট' || unit.toLowerCase() == 'set') {
      return _get({'bn': 'সেট', 'en': 'set', 'ar': 'مجموعة', 'ur': 'سیٹ'});
    }
    if (unit == 'জোড়া' || unit.toLowerCase() == 'pair') {
      return _get({'bn': 'জোড়া', 'en': 'pair', 'ar': 'زوج', 'ur': 'جوڑا'});
    }
    if (unit == 'প্যাকেট' || unit.toLowerCase() == 'packet' || unit.toLowerCase() == 'pkt') {
      return _get({'bn': 'প্যাকেট', 'en': 'pkt', 'ar': 'حزمة', 'ur': 'پیکٹ'});
    }
    if (unit == 'রোল' || unit.toLowerCase() == 'roll') {
      return _get({'bn': 'রোল', 'en': 'roll', 'ar': 'لفة', 'ur': 'رول'});
    }
    if (unit == 'বক্স' || unit.toLowerCase() == 'box') {
      return _get({'bn': 'বক্স', 'en': 'box', 'ar': 'صندوق', 'ur': 'باکس'});
    }
    return unit;
  }

  // Teacher Backup & Gmail
  String get personalBackupGmail => _get({
        'bn': 'ব্যক্তিগত ব্যাকআপ (জিমেইল)',
        'en': 'Personal Backup (Gmail)',
        'ar': 'النسخ الاحتياطي الشخصي (جيميل)',
        'ur': 'ذاتی بیک اپ (جی میل)',
      });
  String get backupDialogSubtitle => _get({
        'bn': 'লগইন করলে ডাটা আসবে, লগআউট করলে চলে যাবে',
        'en': 'Login to sync data. Logout removes device data',
        'ar': 'تسجيل الدخول يستعيد البيانات، وتسجيل الخروج يمسحها من الجهاز',
        'ur': 'لاگ ان کرنے سے ڈیٹا آئے گا، لاگ آؤٹ سے ہٹ جائے گا',
      });
  String get loggedInStatus => _get({
        'bn': 'লগইন আছেন',
        'en': 'Logged in',
        'ar': 'تم تسجيل الدخول',
        'ur': 'لاگ ان ہیں',
      });
  String get logoutBtn => _get({
        'bn': 'লগআউট',
        'en': 'Logout',
        'ar': 'تسجيل الخروج',
        'ur': 'لاگ آؤٹ',
      });
  String get saveToGmailBtn => _get({
        'bn': 'জিমেইলে ব্যাকআপ সংরক্ষণ করুন',
        'en': 'Save Backup to Gmail & Cloud',
        'ar': 'حفظ النسخة الاحتياطية في الجيميل والسحاب',
        'ur': 'جی میل اور کلاؤڈ میں بیک اپ محفوظ کریں',
      });
  String get restorePreviousDataBtn => _get({
        'bn': 'আগের সব ডাটা রিস্টোর করুন',
        'en': 'Restore All Previous Data',
        'ar': 'استعادة كافة البيانات السابقة',
        'ur': 'سابقہ تمام ڈیٹا بحال کریں',
      });
  String get restoreFromFileOrCodeBtn => _get({
        'bn': 'ফাইল বা কোড থেকে রিস্টোর',
        'en': 'Restore from File or Code',
        'ar': 'استعادة من ملف أو رمز',
        'ur': 'فائل یا کوڈ سے بحال کریں',
      });
  String get orRestoreWithCodeBtn => _get({
        'bn': 'অথবা ব্যাকআপ কোড দিয়ে সরাসরি রিস্টোর করুন',
        'en': 'Or restore directly using backup code',
        'ar': 'أو الاستعادة مباشرة باستخدام رمز النسخ',
        'ur': 'یا بیک اپ کوڈ کے ذریعے براہ راست بحال کریں',
      });
  String get enterYourGmail => _get({
        'bn': 'আপনার জিমেইল লিখুন:',
        'en': 'Enter your Gmail:',
        'ar': 'أدخل بريدك الإلكتروني (جيميل):',
        'ur': 'اپنا جی میل لکھیں:',
      });
  String get loginBtn => _get({
        'bn': 'লগইন করুন',
        'en': 'Login',
        'ar': 'تسجيل الدخول',
        'ur': 'لاگ ان کریں',
      });
  String get confirmLogoutTitle => _get({
        'bn': 'লগআউট করতে চান?',
        'en': 'Do you want to logout?',
        'ar': 'هل تريد تسجيل الخروج؟',
        'ur': 'کیا آپ لاگ آؤٹ کرنا چاہتے ہیں؟',
      });
  String get confirmLogoutDesc => _get({
        'bn': 'লগআউট করলে ডিভাইসের সমস্ত ব্যক্তিগত ডাটা সরিয়ে নেওয়া হবে। পুনরায় এই জিমেইল দিয়ে লগইন করলে আপনার সব ডাটা আবার ফিরে আসবে।',
        'en': 'Logging out will remove personal notes and routines from this device. Logging in again with this Gmail will restore everything.',
        'ar': 'سيؤدي تسجيل الخروج إلى مسح الملاحظات والجدول من هذا الجهاز. تسجيل الدخول مجدداً بنفس الجيميل سيعيد كل بياناتك.',
        'ur': 'لاگ آؤٹ کرنے سے اس ڈیوائس سے ذاتی نوٹس اور شیڈول ہٹ جائیں گے۔ دوبارہ اسی جی میل سے لاگ ان کرنے پر سب کچھ واپس آ جائے گا۔',
      });
  String get yesLogout => _get({
        'bn': 'হ্যাঁ, লগআউট করুন',
        'en': 'Yes, Logout',
        'ar': 'نعم، تسجيل الخروج',
        'ur': 'ہاں، لاگ آؤٹ کریں',
      });
  String get restoreModalTitle => _get({
        'bn': 'ফাইল বা কোড থেকে রিস্টোর',
        'en': 'Restore from File or Code',
        'ar': 'استعادة من ملف أو كود',
        'ur': 'فائل یا کوڈ سے بحالی',
      });
  String get pasteBackupCodeHint => _get({
        'bn': 'আপনার পূর্বের ব্যাকআপ টেক্সট বা JSON কোড নিচে পেস্ট করুন:',
        'en': 'Paste your previous backup text or JSON code below:',
        'ar': 'الصق نص النسخة الاحتياطية أو رمز JSON أدناه:',
        'ur': 'اپنا سابقہ بیک اپ ٹیکسٹ یا JSON کوڈ نیچے پیسٹ کریں:',
      });
  String get pasteHerePlaceholder => _get({
        'bn': 'এখানে ব্যাকআপ কোড বা টেক্সট পেস্ট করুন...',
        'en': 'Paste backup code or text here...',
        'ar': 'الصق رمز النسخ الاحتياطي هنا...',
        'ur': 'یہاں بیک اپ کوڈ یا ٹیکسٹ پیسٹ کریں...',
      });
  String get restoreActionBtn => _get({
        'bn': 'রিস্টোর করুন',
        'en': 'Restore',
        'ar': 'استعادة',
        'ur': 'بحال کریں',
      });
  String get restoreSuccessMsg => _get({
        'bn': 'সফলভাবে রিস্টোর হয়েছে!',
        'en': 'Successfully restored!',
        'ar': 'تمت الاستعادة بنجاح!',
        'ur': 'کامیابی سے بحال ہو گیا!',
      });
  String get backupSuccessMsg => _get({
        'bn': 'আপনার সমস্ত নোট ক্লাউডে সফলভাবে সংরক্ষিত হয়েছে এবং জিমেইলে পাঠানো হয়েছে!',
        'en': 'All your notes have been saved to the cloud and sent to Gmail!',
        'ar': 'تم حفظ كافة ملاحظاتك بنجاح في السحاب وإرسالها إلى الجيميل!',
        'ur': 'آپ کے تمام نوٹس کلاؤڈ میں محفوظ کر لیے گئے اور جی میل پر بھیج دیے گئے!',
      });
  String get invalidEmailMsg => _get({
        'bn': 'অনুগ্রহ করে সঠিক জিমেইল অ্যাড্রেস লিখুন!',
        'en': 'Please enter a valid Gmail address!',
        'ar': 'يرجى إدخال عنوان بريد جيميل صحيح!',
        'ur': 'براہ کرم درست جی میل ایڈریس درج کریں!',
      });
  String get logoutSuccessMsg => _get({
        'bn': 'লগআউট সম্পন্ন হয়েছে। ডিভাইস থেকে সব ডাটা সরিয়ে নেওয়া হয়েছে।',
        'en': 'Logged out. All personal data removed from this device.',
        'ar': 'تم تسجيل الخروج بنجاح وتم مسح البيانات من الجهاز.',
        'ur': 'لاگ آؤٹ مکمل ہو گیا۔ تمام ذاتی ڈیٹا ڈیوائس سے ہٹا دیا گیا۔',
      });
  String get restoreErrorMsg => _get({
        'bn': 'রিস্টোর করতে সমস্যা হয়েছে',
        'en': 'Failed to restore',
        'ar': 'تعذرت الاستعادة',
        'ur': 'بحال کرنے میں خرابی',
      });
  String get backupErrorMsg => _get({
        'bn': 'ব্যাকআপ পাঠাতে সমস্যা হয়েছে',
        'en': 'Failed to send backup',
        'ar': 'تعذر إرسال النسخة الاحتياطية',
        'ur': 'بیک اپ بھیجنے میں خرابی',
      });

  // Settings: Teacher Backup Card
  String get teacherBackupSectionHeader => _get({
        'bn': 'ব্যক্তিগত ব্যাকআপ ও জিমেইল',
        'en': 'Personal Backup & Gmail',
        'ar': 'النسخ الاحتياطي الشخصي والجيميل',
        'ur': 'ذاتی بیک اپ اور جی میل',
      });
  String get teacherBackupCardTitle => _get({
        'bn': 'ওস্তাদদের ব্যক্তিগত ব্যাকআপ ও জিমেইল',
        'en': "Teacher's Personal Backup & Gmail",
        'ar': 'النسخ الاحتياطي الشخصي للمعلمين',
        'ur': 'اساتذہ کا ذاتی بیک اپ اور جی میل',
      });
  String get teacherBackupCardSubtitle => _get({
        'bn': 'জিমেইল সেট করুন, নোটস ও রুটিন ব্যাকআপ নিন ও রিস্টোর করুন',
        'en': 'Set Gmail, backup & restore personal notes and routine',
        'ar': 'تعيين الجيميل، والنسخ الاحتياطي واستعادة الملاحظات والجدول',
        'ur': 'جی میل سیٹ کریں، نوٹس اور شیڈول کا بیک اپ اور بحالی',
      });

  // Settings: Admin WhatsApp Field
  String get adminWhatsAppNumberLabel => _get({
        'bn': 'অ্যাডমিন হোয়াটসঅ্যাপ নাম্বার',
        'en': 'Admin WhatsApp Number',
        'ar': 'رقم واتساب المشرف',
        'ur': 'ایڈمن واٹس ایپ نمبر',
      });
  String get adminWhatsAppNumberHint => _get({
        'bn': 'যেমন +88017xxxxxxxx',
        'en': 'e.g. +88017xxxxxxxx',
        'ar': 'مثال: +88017xxxxxxxx',
        'ur': 'مثلاً: +88017xxxxxxxx',
      });
  String get adminWhatsAppSavedSuccess => _get({
        'bn': 'অ্যাডমিন হোয়াটসঅ্যাপ নাম্বার সফলভাবে সংরক্ষিত হয়েছে!',
        'en': 'Admin WhatsApp number saved successfully!',
        'ar': 'تم حفظ رقم واتساب المشرف بنجاح!',
        'ur': 'ایڈمن واٹس ایپ نمبر کامیابی سے محفوظ ہو گیا!',
      });
  String get saved => _get({
        'bn': 'সেভ হয়েছে',
        'en': 'Saved',
        'ar': 'تم الحفظ',
        'ur': 'محفوظ ہو گیا',
      });
  String get notes => _get({
        'bn': 'নোট',
        'en': 'Notes',
        'ar': 'ملاحظات',
        'ur': 'نوٹس',
      });
  String get routine => _get({
        'bn': 'রুটিন',
        'en': 'Routine',
        'ar': 'روتين',
        'ur': 'روٹین',
      });

  // Teacher Notes Page
  String get personalNotesTitle => _get({
        'bn': 'ব্যক্তিগত নোটসমূহ',
        'en': 'Personal Notes',
        'ar': 'الملاحظات الشخصية',
        'ur': 'ذاتی نوٹس',
      });
  String get restorePreviousBackup => _get({
        'bn': 'পূর্বের ব্যাকআপ রিস্টোর করুন',
        'en': 'Restore Previous Backup',
        'ar': 'استعادة النسخة الاحتياطية السابقة',
        'ur': 'سابقہ بیک اپ بحال کریں',
      });
  String get shareAsPdf => _get({
        'bn': 'PDF আকারে শেয়ার',
        'en': 'Share as PDF',
        'ar': 'مشاركة كـ PDF',
        'ur': 'پی ڈی ایف شیئر کریں',
      });
  String get printNote => _get({
        'bn': 'প্রিন্ট করুন',
        'en': 'Print',
        'ar': 'طباعة',
        'ur': 'پرنٹ کریں',
      });
  String get shareAsText => _get({
        'bn': 'সাজানো টেক্সট শেয়ার',
        'en': 'Share as Formatted Text',
        'ar': 'مشاركة كنص منسق',
        'ur': 'متن کی شکل میں شیئر کریں',
      });
  String get editNote => _get({
        'bn': 'নোট এডিট',
        'en': 'Edit Note',
        'ar': 'تعديل الملاحظة',
        'ur': 'نوٹ میں ترمیم کریں',
      });
  String get voiceLanguage => _get({
        'bn': 'ভয়েস ভাষা',
        'en': 'Voice Language',
        'ar': 'لغة الصوت',
        'ur': 'آواز کی زبان',
      });
  String get shareAction => _get({
        'bn': 'শেয়ার করুন',
        'en': 'Share',
        'ar': 'مشاركة',
        'ur': 'شیئر کریں',
      });
  String get fontSizeSmall => _get({
        'bn': 'ছোট',
        'en': 'Small',
        'ar': 'صغير',
        'ur': 'چھوٹا',
      });
  String get fontSizeNormal => _get({
        'bn': 'স্বাভাবিক',
        'en': 'Normal',
        'ar': 'عادي',
        'ur': 'عام',
      });
  String get fontSizeMedium => _get({
        'bn': 'মাঝারি',
        'en': 'Medium',
        'ar': 'متوسط',
        'ur': 'درمیانہ',
      });
  String get fontSizeLarge => _get({
        'bn': 'বড়',
        'en': 'Large',
        'ar': 'كبير',
        'ur': 'بڑا',
      });
  String get fontSizeHuge => _get({
        'bn': 'অনেক বড়',
        'en': 'Huge',
        'ar': 'كبير جداً',
        'ur': 'بہت بڑا',
      });
  String get fontSizeReset => _get({
        'bn': 'রিসেট',
        'en': 'Reset',
        'ar': 'إعادة ضبط',
        'ur': 'ری سیٹ',
      });
  String get no => _get({
        'bn': 'না',
        'en': 'No',
        'ar': 'لا',
        'ur': 'نہیں',
      });
  String get yes => _get({
        'bn': 'হ্যাঁ',
        'en': 'Yes',
        'ar': 'نعم',
        'ur': 'ہاں',
      });
  String get pleaseLoginFirst => _get({
        'bn': 'প্রথমে আপনার জিমেইল দিয়ে লগইন করুন।',
        'en': 'Please login with your Gmail first.',
        'ar': 'يرجى تسجيل الدخول بحساب جيميل أولاً.',
        'ur': 'پہلے اپنے جی میل سے لاگ ان کریں۔',
      });
  String get loginSuccessMsg => _get({
        'bn': 'জিমেইল সফলভাবে লগইন হয়েছে! নোট লিখলে স্বয়ংক্রিয়ভাবে ক্লাউডে ব্যাকআপ থাকবে।',
        'en': 'Gmail logged in successfully! Notes will be automatically backed up.',
        'ar': 'تم تسجيل الدخول بنجاح! سيتم حفظ الملاحظات تلقائياً.',
        'ur': 'جی میل کامیابی سے لاگ ان ہو گیا! نوٹس خودکار طور پر بیک اپ ہو جائیں گے۔',
      });
  String get loginSuccessCloudMsg => _get({
        'bn': 'লগইন সফল! ক্লাউড থেকে আপনার পূর্বের সব ডাটা চলে এসেছে।',
        'en': 'Login successful! All your data has been restored from the cloud.',
        'ar': 'تم تسجيل الدخول بنجاح! تمت استعادة كافة بياناتك من السحاب.',
        'ur': 'لاگ ان کامیاب! کلاؤڈ سے آپ کا تمام ڈیٹا بحال ہو گیا ہے۔',
      });
  String get loginErrorMsg => _get({
        'bn': 'লগইন করতে সমস্যা হয়েছে',
        'en': 'Failed to login',
        'ar': 'تعذر تسجيل الدخول',
        'ur': 'لاگ ان کرنے میں خرابی',
      });
  String get allPreviousDataRestored => _get({
        'bn': 'আপনার আগের সব ডাটা চলে এসেছে!',
        'en': 'All your previous data has been restored!',
        'ar': 'تمت استعادة كافة بياناتك السابقة بنجاح!',
        'ur': 'آپ کا تمام سابقہ ڈیٹا بحال کر دیا گیا ہے!',
      });

  // Helper
  String _get(Map<String, String> values) {
    return values[locale] ?? values['en'] ?? values['bn'] ?? '';
  }
}
