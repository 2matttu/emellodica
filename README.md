# Simulating and Augmenting Melodica Performance on an Embedded System
### Matt Tu
### Advisor: Scott Peterson, Yale University
## Abstract
The field of computer music has grown significantly in the last half century due to
rapid advances in computer hardware and incresaingly robust audio software. At the heart of
computer music is digital audio synthesis, where programmers use a wide range of techniques to
produce realistic sounds. A common application of digital audio synthesis is recreating the
sounds of musical instruments. In this project, we aimed to digitally recreate the sound of the
melodica, which is a musical instrument that combines a keyboard and a mouthpiece, and
furthermore create a system that can simulate the physical performance of a melodica. Initially,
the sonic profile of the melodica was analyzed using fourier spectrum analysis, in which
harmonic frequencies and their amplitudes were recorded. We then used sound synthesis
techniques, such as additive synthesis and filters, to digitally recreate its sonic qualities, and
designed and built an embedded system that uses different sensors and input sources to emulate
the operation and performance of a real melodica. The resulting digital melodica system’s sound
closely resembled that of a real melodica, and the user’s interaction with the system was almost
identical to that of the original instrument. Moreover, we developed additional features that
expanded the musical capability of the electronic melodica system, including programming the
melodica mouthpiece to modulate frequency instead of amplitude, and adding a brass-like
synthesizer. Overall, this project gave more insight into the sonic profile of the melodica and
explored the computational bounds of sound synthesis on an embedded system with limited
resources.

__For full report, see `cpsc490report.pdf`__

__For source code, see `cpsc490src` directory__
