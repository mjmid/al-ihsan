import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maktaba_ihsan/core/providers/settings_provider.dart';

final translationProvider = Provider<AppTranslations>((ref) {
  final locale = ref.watch(appSettingsProvider).locale.languageCode;
  return AppTranslations(locale);
});

class AppTranslations {
  final String locale;
  AppTranslations(this.locale);

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
        'bn': 'শ্রেণী/জামাআত:',
        'en': 'Class:',
        'ar': 'الصف/الجماعة:',
        'ur': 'کلاس/جماعت:'
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
        'bn': 'ক্রমিক নং',
        'en': 'Accession No',
        'ar': 'رقم الباركود',
        'ur': 'ایکشن نمبر'
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
  String get translatorLabel => _get({'bn': 'অনুবাদক', 'en': 'Translator', 'ar': 'المترجم', 'ur': 'مترجم'});
  String get useTeacherDashboard => _get({'bn': 'শিক্ষক ড্যাশবোর্ড', 'en': 'Teacher Dashboard', 'ar': 'لوحة تحكم المعلم', 'ur': 'استاد کا ڈیش بورڈ'});
  String get volumeNoLabel => _get({'bn': 'খন্ড নং', 'en': 'Volume No', 'ar': 'رقم المجلد', 'ur': 'جلد نمبر'});

  // Helper
  String _get(Map<String, String> values) {
    return values[locale] ?? values['en'] ?? values['bn'] ?? '';
  }
}
