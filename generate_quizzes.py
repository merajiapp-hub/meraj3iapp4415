import json
import uuid
import random
import os

# هذا السكربت وظيفته توليد أسئلة بصيغة JSON متوافقة مع قاعدة بياناتك.
# يمكنك لاحقاً استخدام مكتبة firebase-admin لرفعها بضغطة زر.

CATEGORIES = ["رياضيات", "علوم", "تاريخ", "لغة عربية", "فيزياء"]
DIFFICULTIES = ["easy", "medium", "hard", "veryHard"]

def generate_sample_questions(total_per_category=1000):
    all_questions = []
    
    for category in CATEGORIES:
        for i in range(total_per_category):
            diff = random.choice(DIFFICULTIES)
            doc_id = f"{category}_q{i}_{uuid.uuid4().hex[:8]}"
            
            # مثال لبيانات عشوائية (في الواقع يمكنك استخدام ChatGPT/Gemini API هنا لتوليد أسئلة حقيقية)
            question = {
                "id": doc_id,
                "category": category,
                "difficulty": diff,
                "question": f"هذا هو السؤال رقم {i+1} لمادة {category} (مستوى: {diff})؟",
                "options": [
                    "الخيار الأول (خاطئ)",
                    "الخيار الثاني (صحيح)",
                    "الخيار الثالث (خاطئ)",
                    "الخيار الرابع (خاطئ)"
                ],
                "correctIndex": 1,
                "explanation": f"شرح للإجابة الصحيحة للسؤال رقم {i+1}."
            }
            all_questions.append(question)
            
    return all_questions

if __name__ == "__main__":
    print("جاري توليد الأسئلة...")
    questions = generate_sample_questions(50) # عينة 50 سؤال لكل مادة للتجربة (250 سؤال مجموع)
    
    with open("quizzes_seed.json", "w", encoding="utf-8") as f:
        json.dump(questions, f, ensure_ascii=False, indent=4)
        
    print(f"تم بنجاح توليد {len(questions)} سؤال وحفظها في quizzes_seed.json")
    print("لرفعها إلى Firebase Firestore، يمكنك استخدام firebase-admin SDK،")
    print("أو رفعها كدفعة واحدة (Batch Write) باستخدام Node.js أو Python.")
