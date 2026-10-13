# تثبيت ITAM Agent عن طريق Group Policy

يوصى بتوزيع البرنامج كسكربت بدء تشغيل للكمبيوتر. يعمل السكربت بصلاحية
`Local System`، ويشغّل MSI بصمت، ويسجل تفاصيل التثبيت محليًا. لا يحتاج
المستخدم إلى الموافقة أو صلاحيات مسؤول محلي.

## 1. تجهيز الملفات والصلاحيات

1. ابنِ ملف `ITAM_Agent.msi` من الإصدار الحالي `1.0.3`.
2. انسخ ملف MSI إلى مجلد شبكة ثابت، مثل:
   `\\FS01\ITAM-Software\ITAM_Agent.msi`
3. امنح مجموعة `Domain Computers` صلاحية **Read** على المشاركة وعلى صلاحيات
   NTFS للمجلد والملف. يستخدم سكربت بدء التشغيل حساب الكمبيوتر للوصول إلى
   المشاركة، وليس حساب المستخدم المسجل دخوله.
4. انسخ
   [`Install-ITAMAgent-GPO.cmd`](../deploy/Install-ITAMAgent-GPO.cmd)
   إلى مجلد سكربتات الدومين، عادةً:
   `\\<domain>\SYSVOL\<domain>\scripts\`
5. عدّل قيمة `MSI_PATH` داخل السكربت لتطابق مسار UNC الفعلي. لا تستخدم حرف
   قرص شبكة مثل `Z:\`؛ غالبًا لا يكون متاحًا لحساب الكمبيوتر أثناء بدء التشغيل.
6. إذا أصدرت نسخة أحدث، حدّث `DEPLOYMENT_VERSION` في السكربت لتطابق إصدار MSI.
   لكل إصدار رقم علامة مختلف، فيعيد السكربت محاولة التثبيت/الترقية مرة واحدة.

## 2. إنشاء وربط GPO

1. افتح **Group Policy Management** (`gpmc.msc`) من جهاز إدارة الدومين.
2. أنشئ GPO جديدًا، مثل `ITAM Agent - Computer Startup Install`.
3. اربطه بالـ **OU التي تحتوي حسابات أجهزة الكمبيوتر المستهدفة**، وليس فقط
   OU المستخدمين.
4. من **Security Filtering**، اترك `Authenticated Users` أو حدّد مجموعة
   أجهزة مستهدفة. تأكد أن الأجهزة لديها صلاحيتا **Read** و **Apply Group
   Policy** على الـGPO.
5. حرّر الـGPO، ثم اذهب إلى:
   **Computer Configuration → Policies → Windows Settings → Scripts
   (Startup/Shutdown) → Startup → Add**.
6. اختر ملف `Install-ITAMAgent-GPO.cmd` من مجلد سكربتات الدومين. اترك
   **Script Parameters** فارغة.
7. لتأمين توفر الشبكة قبل تشغيل السكربت، فعّل السياسة:
   **Computer Configuration → Policies → Administrative Templates → System
   → Logon → Always wait for the network at computer startup and logon**.

## 3. اختبار التثبيت والتحقق

1. اختبر أولًا على جهاز موجود في OU تجريبية ومسموح له بقراءة مشاركة MSI.
2. على الجهاز، شغّل `gpupdate /force` ثم **أعد تشغيل الكمبيوتر**. سكربت
   بدء التشغيل لا يعمل بمجرد تسجيل الخروج أو تحديث السياسة.
3. بعد إعادة التشغيل، تحقق من وجود:
   `C:\Program Files (x86)\ITAM Agent\ITAMAgent.exe`
   ومن ظهور ITAM Agent في قائمة البرامج. قد يظهر مسار Program Files مختلفًا
   حسب إصدار ويندوز ومعمارية النظام.
4. راجع سجل تثبيت MSI:
   `%windir%\Temp\ITAMAgent-GPO-install-1.0.3.log`
   وسجل تشغيل سكربت GPO:
   `%windir%\Temp\ITAMAgent-GPO-bootstrap.log`
5. إذا لم يبدأ السكربت، افحص تطبيق السياسات عبر `gpresult /h
   "%TEMP%\gpresult.html"`، ثم راجع **Event Viewer → Applications and
   Services Logs → Microsoft → Windows → GroupPolicy → Operational**.
   أخطاء Windows Installer تظهر أيضًا في سجل **Application**.

## ملاحظات

- لا تستخدم `\\server\share` في اختصار شخصي أو جلسة المستخدم؛ يجب أن يكون
  مسار MSI متاحًا لحسابات أجهزة الدومين.
- سكربت التثبيت لا يعيد تشغيل الجهاز تلقائيًا. رمز MSI `3010` يعني أن
  التثبيت نجح وقد يحتاج ويندوز إلى إعادة تشغيل لإكمال بعض التغييرات.
- أُعدّ MSI كتثبيت لكل الجهاز، ورُفع إصداره إلى `1.0.3` حتى يستطيع Windows
  Installer ترقية الإصدارات الأقدم باستخدام `UpgradeCode` نفسه.
