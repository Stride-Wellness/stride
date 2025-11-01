from openai import OpenAI
from typing import Any, Optional
from google.cloud.firestore_v1.client import Client as FirestoreClient
from datetime import datetime
import json

from functions.user import get_user_by_id_data
from models.assessment import Assessment
from models.exercise import Exercise, ExerciseType, DifficultyLevel
from models.user import ClientUser


def _format_prompt(user_data: ClientUser, user_history: list[Assessment]) -> str:
    """
    Format user data and assessment history into an AI-friendly prompt.
    
    Args:
        user_data: ClientUser model with profile information
        user_history: List of Assessment models ordered by timestamp
        
    Returns:
        Formatted string prompt for AI model
    """
    # Header with user information
    prompt_parts = [
        "=== CLIENT PROFILE ===",
        f"Name: {user_data.name}",
        f"User ID: {user_data.id}",
        f"Status: {user_data.status}",
        f"Account Created: {user_data.created_at.strftime('%Y-%m-%d')}",
        ""
    ]
    
    # Add profile information if available
    if user_data.profile:
        prompt_parts.append("--- Personal Information ---")
        
        if user_data.profile.phone:
            prompt_parts.append(f"Phone: {user_data.profile.phone}")
        
        if user_data.profile.date_of_birth:
            prompt_parts.append(f"Date of Birth: {user_data.profile.date_of_birth}")
        
        # Emergency contact
        if user_data.profile.emergency_contact:
            ec = user_data.profile.emergency_contact
            prompt_parts.extend([
                "",
                "--- Emergency Contact ---",
                f"Name: {ec.name}",
                f"Phone: {ec.phone}",
                f"Relationship: {ec.relationship}"
            ])
        
        # Medical information
        if user_data.profile.medical_info:
            med = user_data.profile.medical_info
            prompt_parts.extend([
                "",
                "--- Medical Information ---",
                f"Mobility: {med.mobility}"
            ])
            
            if med.conditions:
                prompt_parts.append(f"Medical Conditions: {', '.join(med.conditions)}")
            
            if med.medications:
                prompt_parts.append(f"Current Medications: {', '.join(med.medications)}")
            
            if med.notes:
                prompt_parts.append(f"Additional Notes: {med.notes}")
        
        prompt_parts.append("")
    
    # Assessment history
    if user_history:
        prompt_parts.extend([
            "=== ASSESSMENT HISTORY ===",
            f"Total Assessments: {len(user_history)}",
            ""
        ])
        
        # Sort by timestamp (most recent first)
        sorted_history = sorted(user_history, key=lambda a: a.timestamp, reverse=True)
        
        for idx, assessment in enumerate(sorted_history, 1):
            prompt_parts.extend([
                f"--- Assessment #{idx} ---",
                f"Date: {assessment.timestamp.strftime('%Y-%m-%d %H:%M')}",
                f"Assessment Name: {assessment.name}",
                ""
            ])
            
            # Format questions and answers
            if assessment.questions and assessment.answers:
                prompt_parts.append("Questions & Answers:")
                
                for question_id, question_text in assessment.questions.items():
                    answer = assessment.answers.get(question_id, "No answer provided")
                    prompt_parts.extend([
                        f"  Q: {question_text}",
                        f"  A: {answer}",
                        ""
                    ])
            
            # Add separator between assessments
            if idx < len(sorted_history):
                prompt_parts.append("---")
                prompt_parts.append("")
    else:
        prompt_parts.extend([
            "=== ASSESSMENT HISTORY ===",
            "No assessment history available for this client.",
            ""
        ])
    
    # Add context for the AI
    prompt_parts.extend([
        "=== TASK ===",
        "Based on the client profile and assessment history above, generate a personalized exercise plan that:",
        "1. Takes into account their mobility level and medical conditions",
        "2. Considers their assessment responses and progress over time",
        "3. Provides safe, appropriate exercises for their current capabilities",
        "4. Includes a balanced mix of physical exercises AND brain games/cognitive activities",
        "5. Brain games should include memory exercises, puzzles, word games, or cognitive challenges - these must be completeable with 0 extra equipment, and on the spot, for example count the number of items around you and recall them after a minute.",
        "6. Includes clear instructions and modifications as needed",
        ""
    ])
    
    return "\n".join(prompt_parts)


def _get_exercise_json_schema() -> dict[str, Any]:
    """
    Get the JSON schema for the exercise response format
    """
    return {
        "type": "object",
        "properties": {
            "exercises": {
                "type": "array",
                "description": "Array of 3-5 personalized exercises and brain games (include both physical and cognitive activities)",
                "items": {
                    "type": "object",
                    "properties": {
                        "title": {
                            "type": "string",
                            "description": "Clear, descriptive exercise name"
                        },
                        "description": {
                            "type": "string",
                            "description": "Brief overview of the exercise and its purpose"
                        },
                        "exerciseType": {
                            "type": "string",
                            "enum": ["physical", "stretching", "balance", "strength", "cardio", "memory", "cognitive", "puzzle"],
                            "description": "Type of exercise or brain game"
                        },
                        "difficulty": {
                            "type": "string",
                            "enum": ["beginner", "intermediate", "advanced"],
                            "description": "Difficulty level appropriate for the client"
                        },
                        "durationMinutes": {
                            "type": "integer",
                            "description": "How long to perform the exercise"
                        },
                        "repetitions": {
                            "type": "integer",
                            "description": "Number of repetitions per set (if applicable)"
                        },
                        "sets": {
                            "type": "integer",
                            "description": "Number of sets to perform"
                        },
                        "restBetweenSetsSeconds": {
                            "type": "integer",
                            "description": "Rest time between sets in seconds"
                        },
                        "instructions": {
                            "type": "array",
                            "description": "Step-by-step instructions",
                            "items": {
                                "type": "object",
                                "properties": {
                                    "stepNumber": {"type": "integer"},
                                    "instruction": {"type": "string"}
                                },
                                "required": ["stepNumber", "instruction"]
                            }
                        },
                        "modifications": {
                            "type": "array",
                            "description": "Easier or harder variations",
                            "items": {
                                "type": "object",
                                "properties": {
                                    "level": {
                                        "type": "string",
                                        "description": "e.g., 'easier', 'harder', 'seated', 'with support'"
                                    },
                                    "description": {"type": "string"}
                                },
                                "required": ["level", "description"]
                            }
                        },
                        "equipmentNeeded": {
                            "type": "array",
                            "items": {"type": "string"},
                            "description": "List of equipment needed (empty if none)"
                        },
                        "safety": {
                            "type": "object",
                            "properties": {
                                "contraindications": {
                                    "type": "array",
                                    "items": {"type": "string"},
                                    "description": "When NOT to do this exercise"
                                },
                                "warnings": {
                                    "type": "array",
                                    "items": {"type": "string"},
                                    "description": "Important safety warnings"
                                },
                                "tips": {
                                    "type": "array",
                                    "items": {"type": "string"},
                                    "description": "Safety tips and best practices"
                                }
                            }
                        },
                        "targetMuscles": {
                            "type": "array",
                            "items": {"type": "string"},
                            "description": "Muscles or body areas targeted"
                        },
                        "benefits": {
                            "type": "array",
                            "items": {"type": "string"},
                            "description": "Expected benefits from this exercise"
                        },
                        "notes": {
                            "type": "string",
                            "description": "Additional notes or considerations for this specific client"
                        }
                    },
                    "required": ["title", "description", "exerciseType", "difficulty", "instructions"]
                }
            }
        },
        "required": ["exercises"]
    }


def generate_exercise_plan_with_ai(
    openai_client: OpenAI,
    db: FirestoreClient,
    user_id: str,
    assessment_id: Optional[str] = None,
    user_requests: Optional[str] = None,
) -> tuple[list[Exercise], str | None]:
    """
    Generate exercise plan using OpenAI based on user input
    Returns (exercise_list, error_message)
    """
    try:
        # Get user data
        user_data, error = get_user_by_id_data(db, user_id)
        if error or user_data is None:
            return [], error or "User not found"
        
        # Ensure it's a client user
        if user_data.type != "client":
            return [], "Exercise plans can only be generated for client users"
        
        # Get user's assessment history
        assessments_ref = db.collection("assessments").where("userId", "==", user_id)
        assessment_docs = assessments_ref.stream()
        
        user_history = []
        for doc in assessment_docs:
            assessment_dict = doc.to_dict()
            if assessment_dict:
                assessment_dict["id"] = doc.id
                try:
                    assessment = Assessment.from_dict(assessment_dict)
                    user_history.append(assessment)
                except Exception as e:
                    print(f"Warning: Could not parse assessment {doc.id}: {e}")
                    continue
        
        # Format prompt with user data and history
        base_prompt = _format_prompt(user_data, user_history)
        
        # Add user-specific requests if provided
        if user_requests:
            base_prompt += f"\n\n=== ADDITIONAL REQUESTS ===\n{user_requests}\n"
        
        # Add JSON schema instructions
        schema = _get_exercise_json_schema()
        base_prompt += f"\n\n=== OUTPUT FORMAT ===\nGenerate your response in JSON format matching this exact schema:\n{json.dumps(schema, indent=2)}\n"

        response = openai_client.chat.completions.create(
            model="gpt-4-turbo-preview",
            messages=[
                {
                    "role": "system",
                    "content": "You are an experienced physical therapist, exercise physiologist, and cognitive health specialist. Generate personalized, safe exercise plans and brain games based on client profiles and assessment history. Include a mix of physical exercises and cognitive activities (memory games, puzzles, brain teasers) appropriate for the client's abilities. Always output valid JSON matching the provided schema exactly.",
                },
                {"role": "user", "content": base_prompt},
            ],
            response_format={"type": "json_object"},
        )

        # Parse response
        result = response.choices[0].message.content
        if not result:
            return [], "Empty response from AI"

        exercise_data = json.loads(result)
        exercises_json = exercise_data.get("exercises", [])
        
        # Convert JSON to Exercise model instances
        exercises = []
        now = datetime.now()
        base_assessment_id = assessment_id or "initial_assessment"
        
        for idx, ex_json in enumerate(exercises_json):
            try:
                # Add required metadata fields
                ex_json["id"] = f"{user_id}_{base_assessment_id}_{idx}_{int(now.timestamp())}"
                ex_json["createdFor"] = user_id
                ex_json["basedOff"] = base_assessment_id
                ex_json["createdAt"] = now
                ex_json["usedAt"] = []
                
                # Parse into Exercise model
                exercise = Exercise.from_dict(ex_json)
                exercises.append(exercise)
                
            except Exception as e:
                print(f"Warning: Could not parse exercise {idx}: {e}")
                continue
        
        if not exercises:
            return [], "Failed to parse any exercises from AI response"

        return exercises, None

    except Exception as e:
        print(f"Error generating exercise plan: {str(e)}")
        import traceback
        traceback.print_exc()
        return [], f"Error generating exercise plan: {str(e)}"
