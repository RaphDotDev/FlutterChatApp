import 'package:app/utils/constants.dart';
import 'package:flutter/material.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //backgroundColor: AppColor.primaryColor,
      body: SafeArea(
        child: Container(
          height: MediaQuery.sizeOf(context).height,
          color: AppColor.primaryColor,
          child: Stack(
            children: [
                Positioned.fill(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsetsGeometry.only(top:100),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColor.primaryColor, width: 2
                                ),                   
                              ),
                              child: const Icon(
                                Icons.chat_bubble_outline,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 10,),
                            Text(
                              'Chat Application',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 30.0,
                                fontWeight: FontWeight.w700
                              ),
                            )
                        ],
                        ), 
                      )
                    ],
                  )
                ),

            //Background with curved white part
              Positioned.fill(
                child: Column(
                  children: [
                  const Spacer(),
                   Container(
                      height: MediaQuery.sizeOf(context).height *0.15,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30)
                          )
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pushNamed('/login');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:AppColor.primaryColor,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Login',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                   Navigator.of(context).pushNamed('/register');
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: BorderSide(color: AppColor.primaryColor, width: 2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Register Now',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColor.primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                )
                ),
            ],
          ),
        )
        ),
    );
  }
}
