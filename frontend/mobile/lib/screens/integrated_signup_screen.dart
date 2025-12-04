import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class IntegratedSignupScreen extends StatefulWidget {
  const IntegratedSignupScreen({super.key});

  @override
  State<IntegratedSignupScreen> createState() => _IntegratedSignupScreenState();
}

class _IntegratedSignupScreenState extends State<IntegratedSignupScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  // 사용자 정보
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _userPhoneController = TextEditingController();
  final _userAgeController = TextEditingController();
  final _userAddressController = TextEditingController();

  // 시니어 정보
  final _seniorNameController = TextEditingController();
  final _seniorPhoneController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _seniorAgeController = TextEditingController();
  final _seniorAddressController = TextEditingController();

  // 추가 정보
  String _selectedUserGender = 'male';
  String _selectedSeniorGender = 'female';

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _userPhoneController.dispose();
    _seniorNameController.dispose();
    _seniorPhoneController.dispose();
    _relationshipController.dispose();
    _seniorAgeController.dispose();
    super.dispose();
  }

  Future<void> _handleIntegratedSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (kDebugMode) {
        print('🔐 통합 회원가입 시작: ${_emailController.text.trim()}');
      }

      // 나이를 숫자로 변환
      final age = int.tryParse(_seniorAgeController.text.trim());
      if (age == null) {
        _showSnackBar('올바른 나이를 입력해주세요');
        return;
      }

      // 통합 회원가입 - 사용자 정보와 시니어 정보를 함께 저장
      final userAge = int.tryParse(_userAgeController.text.trim()) ?? 0;

      await _authService.integratedSignUp(
        // 사용자 정보
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        role: 'caregiver',
        userPhone: _userPhoneController.text.trim(),
        userGender: _selectedUserGender,
        userAge: userAge,
        userAddress: _userAddressController.text.trim(),
        // 시니어 정보
        seniorName: _seniorNameController.text.trim(),
        seniorPhone: _seniorPhoneController.text.trim(),
        seniorAge: age,
        seniorGender: _selectedSeniorGender,
        seniorAddress: _seniorAddressController.text.trim(),
        relationship: _relationshipController.text.trim(),
      );

      if (kDebugMode) {
        print('✅ 통합 회원가입 완료');
      }

      _showSnackBar('회원가입이 완료되었습니다!');

      // 홈 화면으로 이동
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (error) {
      if (kDebugMode) {
        print('❌ 통합 회원가입 실패: $error');
      }
      _showSnackBar('회원가입에 실패했습니다: ${error.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('시니어 헬스케어 가입'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 안내 메시지
              Card(
                color: Colors.blue.shade50,
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(Icons.family_restroom, color: Colors.blue, size: 40),
                      SizedBox(height: 10),
                      Text(
                        '보호자와 시니어 정보를 입력해주세요',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '한 번만 입력하시면 모든 설정이 완료됩니다',
                        style: TextStyle(fontSize: 14, color: Colors.blue),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 보호자 정보 섹션
              Text(
                '👤 보호자 정보',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 16),

              // 보호자 이름
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '보호자 이름',
                  hintText: '김보호자',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '보호자 이름을 입력해주세요';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 이메일
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: '이메일',
                  hintText: 'caregiver@example.com',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '이메일을 입력해주세요';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(value)) {
                    return '올바른 이메일 형식을 입력해주세요';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 보호자 전화번호
              TextFormField(
                controller: _userPhoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: '보호자 전화번호',
                  hintText: '010-1234-5678',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '보호자 전화번호를 입력해주세요';
                  }
                  if (!RegExp(r'^[0-9\-]+$').hasMatch(value)) {
                    return '올바른 전화번호 형식을 입력해주세요';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 비밀번호
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: '비밀번호',
                  hintText: '6자 이상 입력',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '비밀번호를 입력해주세요';
                  }
                  if (value.length < 6) {
                    return '비밀번호는 6자 이상이어야 합니다';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 보호자 성별
              DropdownButtonFormField<String>(
                initialValue: _selectedUserGender,
                decoration: const InputDecoration(
                  labelText: '보호자 성별',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('남성')),
                  DropdownMenuItem(value: 'female', child: Text('여성')),
                  DropdownMenuItem(value: 'other', child: Text('기타')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedUserGender = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '보호자 성별을 선택해주세요';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 보호자 나이
              TextFormField(
                controller: _userAgeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '보호자 나이',
                  hintText: '35',
                  prefixIcon: Icon(Icons.cake),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '보호자 나이를 입력해주세요';
                  }
                  final age = int.tryParse(value);
                  if (age == null || age < 18 || age > 100) {
                    return '올바른 나이를 입력해주세요 (18-100)';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 보호자 주소
              TextFormField(
                controller: _userAddressController,
                decoration: const InputDecoration(
                  labelText: '보호자 주소',
                  hintText: '서울시 강남구',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '보호자 주소를 입력해주세요';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // 시니어 정보 섹션
              Text(
                '👴 시니어 정보',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 16),

              // 시니어 이름
              TextFormField(
                controller: _seniorNameController,
                decoration: const InputDecoration(
                  labelText: '시니어 이름',
                  hintText: '할머니, 어머니, 김○○',
                  prefixIcon: Icon(Icons.elderly),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '시니어 이름을 입력해주세요';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 관계
              TextFormField(
                controller: _relationshipController,
                decoration: const InputDecoration(
                  labelText: '관계',
                  hintText: '할머니, 어머니, 아버지 등',
                  prefixIcon: Icon(Icons.family_restroom),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '관계를 입력해주세요';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 나이
              TextFormField(
                controller: _seniorAgeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '나이',
                  hintText: '75',
                  prefixIcon: Icon(Icons.cake),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '나이를 입력해주세요';
                  }
                  final age = int.tryParse(value);
                  if (age == null || age < 1 || age > 120) {
                    return '올바른 나이를 입력해주세요 (1-120)';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 성별
              DropdownButtonFormField<String>(
                initialValue: _selectedSeniorGender,
                decoration: const InputDecoration(
                  labelText: '성별',
                  prefixIcon: Icon(Icons.wc),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'female', child: Text('여성')),
                  DropdownMenuItem(value: 'male', child: Text('남성')),
                  DropdownMenuItem(value: 'other', child: Text('기타')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedSeniorGender = value!;
                  });
                },
              ),

              const SizedBox(height: 16),

              // 시니어 연락처 (필수)
              TextFormField(
                controller: _seniorPhoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: '시니어 연락처',
                  hintText: '010-1234-5678',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '시니어 연락처를 입력해주세요';
                  }
                  if (!RegExp(r'^[0-9\-]+$').hasMatch(value)) {
                    return '올바른 연락처 형식을 입력해주세요';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 시니어 주소
              TextFormField(
                controller: _seniorAddressController,
                decoration: const InputDecoration(
                  labelText: '시니어 주소',
                  hintText: '서울시 강남구',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '시니어 주소를 입력해주세요';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // 가입 버튼
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleIntegratedSignup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          '가입 완료',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // 안내 메시지
              const Text(
                '• 입력하신 정보는 안전하게 암호화되어 저장됩니다\n'
                '• 시니어 정보는 나중에 설정에서 수정할 수 있습니다',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
